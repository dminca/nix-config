// Command pins checks and bumps the manually pinned sources of this repo.
//
// Every hand-pinned source (release assets, browser/editor extensions,
// commit pins, Caddy plugins) lives in a `<name>.pin.json` next to the Nix
// file that reads it with `lib.importJSON`. This tool finds them all, asks
// upstream for the newest release/commit and rewrites version/rev/url/hash in
// the JSON only; it never edits Nix code. Hashes come from Nix itself
// (`nix store prefetch-file`, `nix flake prefetch`, or a fixed-output build).
// Flake inputs are not pins: update those with `nix flake update`.
//
//	pins [-root DIR] list
//	pins [-root DIR] check  [NAME...]   read-only; exit 1 on lookup errors
//	pins [-root DIR] update [NAME...]   rewrite outdated pins; exit 1 on any failure
//
// Kinds:
//
//	github-release      repo, tagPrefix, version, optional prerelease=true,
//	                    assets.<key>.{file,url,hash}; `file` may use {version}
//	github-commit       owner, repo, branch, rev, hash (head of branch)
//	amo                 slug, addonId, version, url, hash (addons.mozilla.org)
//	vscode-marketplace  publisher, name, version, hash
//	caddy-plugin        module, version, host, hash (caddy.withPlugins hash;
//	                    `update` must run on nixosConfigurations.<host>'s system)
//
// GITHUB_TOKEN is used, if set, to raise the GitHub API rate limit.
package main

import (
	"bytes"
	"encoding/base64"
	"encoding/hex"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"io"
	"io/fs"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"sort"
	"strings"
	"time"
)

type Pin = map[string]any

// Hooks replaced in tests.
var (
	getJSON     = httpJSON
	prefetchURL = func(url string) (string, error) {
		return nixHash("store", "prefetch-file", "--json", "--hash-type", "sha256", url)
	}
	prefetchGitHub = func(owner, repo, rev string) (string, error) {
		return nixHash("flake", "prefetch", "--json", fmt.Sprintf("github:%s/%s/%s", owner, repo, rev))
	}
	caddyHash = caddyPluginHash
	root      = "."
)

func str(p Pin, key string) string {
	v, ok := p[key].(string)
	if !ok {
		panic(fmt.Errorf("missing string field %q", key))
	}
	return v
}

func clone(p Pin) Pin {
	b, _ := json.Marshal(p)
	var c Pin
	_ = json.Unmarshal(b, &c)
	return c
}

func httpJSON(url string, body any, headers map[string]string, out any) error {
	var rd io.Reader
	method := "GET"
	if body != nil {
		b, err := json.Marshal(body)
		if err != nil {
			return err
		}
		rd, method = bytes.NewReader(b), "POST"
	}
	req, err := http.NewRequest(method, url, rd)
	if err != nil {
		return err
	}
	req.Header.Set("User-Agent", "dminca-nix-config-pins")
	if body != nil {
		req.Header.Set("Content-Type", "application/json")
	}
	if strings.HasPrefix(url, "https://api.github.com/") {
		req.Header.Set("Accept", "application/vnd.github+json")
		if t := os.Getenv("GITHUB_TOKEN"); t != "" {
			req.Header.Set("Authorization", "Bearer "+t)
		}
	}
	for k, v := range headers {
		req.Header.Set(k, v)
	}
	resp, err := (&http.Client{Timeout: 60 * time.Second}).Do(req)
	if err != nil {
		return fmt.Errorf("request failed: %w", err)
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("request failed: %s: %s", url, resp.Status)
	}
	if err := json.NewDecoder(resp.Body).Decode(out); err != nil {
		return fmt.Errorf("bad JSON from %s: %w", url, err)
	}
	return nil
}

func runNix(args ...string) ([]byte, error) {
	fmt.Fprintln(os.Stderr, "  $ nix "+strings.Join(args, " "))
	cmd := exec.Command("nix", args...)
	var stderr bytes.Buffer
	cmd.Stderr = &stderr
	out, err := cmd.Output()
	if err != nil {
		return out, fmt.Errorf("nix %s failed: %w: %s", args[0], err, strings.TrimSpace(stderr.String()))
	}
	return out, nil
}

func nixHash(args ...string) (string, error) {
	out, err := runNix(args...)
	if err != nil {
		return "", err
	}
	var r struct{ Hash string }
	if err := json.Unmarshal(out, &r); err != nil || r.Hash == "" {
		return "", fmt.Errorf("no hash in nix output %q", out)
	}
	return r.Hash, nil
}

func sriFromPrefixed(v string) (string, error) {
	algo, digest, _ := strings.Cut(v, ":")
	b, err := hex.DecodeString(digest)
	if algo != "sha256" || err != nil || len(b) != 32 {
		return "", fmt.Errorf("unsupported upstream hash %q", v)
	}
	return "sha256-" + base64.StdEncoding.EncodeToString(b), nil
}

// --- github-release ---------------------------------------------------------

type Release struct {
	TagName     string `json:"tag_name"`
	PublishedAt string `json:"published_at"`
	Prerelease  bool   `json:"prerelease"`
	Draft       bool   `json:"draft"`
	Assets      []struct {
		Name string `json:"name"`
	} `json:"assets"`
}

func githubReleases(repo string) ([]Release, error) {
	var all []Release
	for page := 1; page <= 10; page++ {
		var batch []Release
		url := fmt.Sprintf("https://api.github.com/repos/%s/releases?per_page=100&page=%d", repo, page)
		if err := getJSON(url, nil, nil, &batch); err != nil {
			return nil, err
		}
		if len(batch) == 0 {
			break
		}
		all = append(all, batch...)
	}
	return all, nil
}

func selectRelease(rs []Release, prefix string, pre bool) (Release, error) {
	var best Release
	for _, r := range rs {
		if r.Draft || !strings.HasPrefix(r.TagName, prefix) || (r.Prerelease && !pre) {
			continue
		}
		if r.PublishedAt > best.PublishedAt { // RFC 3339 UTC sorts lexically
			best = r
		}
	}
	if best.TagName == "" {
		channel := "stable release"
		if pre {
			channel = "release"
		}
		return best, fmt.Errorf("no %s with tag prefix %q", channel, prefix)
	}
	return best, nil
}

func releaseTarget(p Pin, rs []Release) (string, Pin, error) {
	prefix, _ := p["tagPrefix"].(string)
	pre, _ := p["prerelease"].(bool)
	latest, err := selectRelease(rs, prefix, pre)
	if err != nil {
		return "", nil, err
	}
	for _, r := range rs {
		if r.TagName == prefix+str(p, "version") && r.PublishedAt > latest.PublishedAt {
			return "", nil, fmt.Errorf("refusing downgrade from %s to %s", r.TagName, latest.TagName)
		}
	}
	version := strings.TrimPrefix(latest.TagName, prefix)
	names := map[string]bool{}
	for _, a := range latest.Assets {
		names[a.Name] = true
	}
	n := clone(p)
	n["version"] = version
	assets, ok := n["assets"].(map[string]any)
	if !ok || len(assets) == 0 {
		return "", nil, errors.New("missing assets")
	}
	for _, key := range sortedKeys(assets) {
		a := assets[key].(map[string]any)
		file := strings.ReplaceAll(str(a, "file"), "{version}", version)
		if !names[file] {
			return "", nil, fmt.Errorf("release %s has no asset %q (for %s)", latest.TagName, file, key)
		}
		a["url"] = fmt.Sprintf("https://github.com/%s/releases/download/%s/%s", str(p, "repo"), latest.TagName, file)
	}
	return version, n, nil
}

func githubRelease(p Pin, hashing bool) (string, Pin, error) {
	rs, err := githubReleases(str(p, "repo"))
	if err != nil {
		return "", nil, err
	}
	version, n, err := releaseTarget(p, rs)
	if err != nil || version == str(p, "version") {
		return version, nil, err
	}
	if hashing {
		assets := n["assets"].(map[string]any)
		for _, key := range sortedKeys(assets) {
			a := assets[key].(map[string]any)
			if a["hash"], err = prefetchURL(str(a, "url")); err != nil {
				return "", nil, err
			}
		}
	}
	return version, n, nil
}

// --- github-commit ----------------------------------------------------------

func githubCommit(p Pin, hashing bool) (string, Pin, error) {
	slug := str(p, "owner") + "/" + str(p, "repo")
	var head struct{ SHA string }
	if err := getJSON(fmt.Sprintf("https://api.github.com/repos/%s/commits/%s", slug, str(p, "branch")), nil, nil, &head); err != nil {
		return "", nil, err
	}
	if head.SHA == str(p, "rev") {
		return head.SHA[:12], nil, nil
	}
	var cmp struct{ Status string }
	if err := getJSON(fmt.Sprintf("https://api.github.com/repos/%s/compare/%s...%s", slug, str(p, "rev"), head.SHA), nil, nil, &cmp); err != nil {
		return "", nil, err
	}
	if cmp.Status != "ahead" {
		return "", nil, fmt.Errorf("%s head %s is %s relative to pinned rev", str(p, "branch"), head.SHA[:12], cmp.Status)
	}
	n := clone(p)
	n["rev"] = head.SHA
	if hashing {
		h, err := prefetchGitHub(str(p, "owner"), str(p, "repo"), head.SHA)
		if err != nil {
			return "", nil, err
		}
		n["hash"] = h
	}
	return head.SHA[:12], n, nil
}

// --- amo --------------------------------------------------------------------

func amo(p Pin, hashing bool) (string, Pin, error) {
	var d struct {
		GUID           string `json:"guid"`
		CurrentVersion struct {
			Version string `json:"version"`
			File    struct{ URL, Hash string }
		} `json:"current_version"`
	}
	if err := getJSON("https://addons.mozilla.org/api/v5/addons/addon/"+str(p, "slug")+"/", nil, nil, &d); err != nil {
		return "", nil, err
	}
	if d.GUID != str(p, "addonId") {
		return "", nil, fmt.Errorf("AMO guid %q != addonId %q", d.GUID, str(p, "addonId"))
	}
	v := d.CurrentVersion.Version
	if v == str(p, "version") {
		return v, nil, nil
	}
	n := clone(p)
	n["version"], n["url"] = v, d.CurrentVersion.File.URL
	if hashing {
		want, err := sriFromPrefixed(d.CurrentVersion.File.Hash)
		if err != nil {
			return "", nil, err
		}
		got, err := prefetchURL(d.CurrentVersion.File.URL)
		if err != nil {
			return "", nil, err
		}
		if got != want {
			return "", nil, fmt.Errorf("downloaded hash %s != AMO hash %s", got, want)
		}
		n["hash"] = got
	}
	return v, n, nil
}

// --- vscode-marketplace -----------------------------------------------------

type vsVersion struct {
	Version        string `json:"version"`
	TargetPlatform string `json:"targetPlatform"`
	Properties     []struct{ Key, Value string }
}

func latestVSCodeVersion(vs []vsVersion) (string, error) {
	for _, v := range vs { // newest first
		pre := false
		for _, p := range v.Properties {
			pre = pre || (p.Key == "Microsoft.VisualStudio.Code.PreRelease" && p.Value == "true")
		}
		if !pre && v.TargetPlatform == "" {
			return v.Version, nil
		}
	}
	return "", errors.New("no stable universal version found")
}

func vscodeMarketplace(p Pin, hashing bool) (string, Pin, error) {
	pub, name := str(p, "publisher"), str(p, "name")
	query := map[string]any{
		"filters": []any{map[string]any{"criteria": []any{map[string]any{"filterType": 7, "value": pub + "." + name}}}},
		"flags":   17,
	}
	var d struct {
		Results []struct {
			Extensions []struct{ Versions []vsVersion }
		}
	}
	err := getJSON("https://marketplace.visualstudio.com/_apis/public/gallery/extensionquery", query,
		map[string]string{"Accept": "application/json;api-version=3.0-preview.1"}, &d)
	if err != nil {
		return "", nil, err
	}
	if len(d.Results) == 0 || len(d.Results[0].Extensions) == 0 {
		return "", nil, fmt.Errorf("extension %s.%s not found", pub, name)
	}
	v, err := latestVSCodeVersion(d.Results[0].Extensions[0].Versions)
	if err != nil || v == str(p, "version") {
		return v, nil, err
	}
	n := clone(p)
	n["version"] = v
	if hashing {
		// Same URL as nixpkgs' vscode-utils.extensionsFromVscodeMarketplace.
		url := fmt.Sprintf("https://%s.gallery.vsassets.io/_apis/public/gallery/publisher/%s/extension/%s/%s/assetbyname/Microsoft.VisualStudio.Services.VSIXPackage", pub, pub, name, v)
		if n["hash"], err = prefetchURL(url); err != nil {
			return "", nil, err
		}
	}
	return v, n, nil
}

// --- caddy-plugin -----------------------------------------------------------

// caddy-src.nix builds the caddy.withPlugins vendored source with a fake hash
// (natively on the host's system only); the real one is read from the
// hash-mismatch error.

var gotHash = regexp.MustCompile(`got:\s+(sha256-[A-Za-z0-9+/]{43}=)`)

func caddyPluginHash(host, plugin string) (string, error) {
	abs, err := filepath.Abs(root)
	if err != nil {
		return "", err
	}
	_, err = runNix("build", "--no-link", "--impure", "--file", filepath.Join(abs, "scripts/pins/caddy-src.nix"),
		"--argstr", "root", abs, "--argstr", "host", host, "--argstr", "plugin", plugin)
	if err == nil {
		return "", errors.New("fake hash unexpectedly accepted")
	}
	m := gotHash.FindStringSubmatch(err.Error())
	if m == nil {
		return "", err
	}
	return m[1], nil
}

func caddyPlugin(p Pin, hashing bool) (string, Pin, error) {
	mod := str(p, "module")
	var d struct{ Version string }
	if err := getJSON("https://proxy.golang.org/"+strings.ToLower(mod)+"/@latest", nil, nil, &d); err != nil {
		return "", nil, err
	}
	n := clone(p)
	n["version"] = d.Version
	if hashing {
		// Also recompute when only nixpkgs' caddy changed: the hash covers both.
		h, err := caddyHash(str(p, "host"), mod+"@"+d.Version)
		if err != nil {
			return "", nil, err
		}
		if d.Version == str(p, "version") && h == str(p, "hash") {
			return d.Version, nil, nil
		}
		n["hash"] = h
		return d.Version, n, nil
	}
	if d.Version == str(p, "version") {
		return d.Version, nil, nil
	}
	return d.Version, n, nil
}

var kinds = map[string]func(Pin, bool) (string, Pin, error){
	"github-release":     githubRelease,
	"github-commit":      githubCommit,
	"amo":                amo,
	"vscode-marketplace": vscodeMarketplace,
	"caddy-plugin":       caddyPlugin,
}

// --- driver -----------------------------------------------------------------

func sortedKeys[V any](m map[string]V) []string {
	keys := make([]string, 0, len(m))
	for k := range m {
		keys = append(keys, k)
	}
	sort.Strings(keys)
	return keys
}

func discover(dir string) (map[string]string, error) {
	pins := map[string]string{}
	err := filepath.WalkDir(dir, func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return err
		}
		if d.IsDir() && (d.Name() == ".git" || d.Name() == "result" || d.Name() == "node_modules") {
			return filepath.SkipDir
		}
		if name, ok := strings.CutSuffix(d.Name(), ".pin.json"); ok && !d.IsDir() {
			if prev, dup := pins[name]; dup {
				return fmt.Errorf("duplicate pin name %s: %s and %s", name, prev, path)
			}
			pins[name] = path
		}
		return nil
	})
	return pins, err
}

func writeAtomic(path string, p Pin) error {
	b, err := json.MarshalIndent(p, "", "  ")
	if err != nil {
		return err
	}
	tmp, err := os.CreateTemp(filepath.Dir(path), "."+filepath.Base(path)+".")
	if err != nil {
		return err
	}
	defer os.Remove(tmp.Name())
	if _, err := tmp.Write(append(b, '\n')); err != nil {
		tmp.Close()
		return err
	}
	if err := tmp.Close(); err != nil {
		return err
	}
	return os.Rename(tmp.Name(), path)
}

func label(p Pin) string {
	if v, ok := p["version"].(string); ok {
		return v
	}
	if r, ok := p["rev"].(string); ok && len(r) >= 12 {
		return r[:12]
	}
	return ""
}

func process(cmd, name, path string, stdout io.Writer) (err error) {
	defer func() {
		if r := recover(); r != nil {
			err = fmt.Errorf("%v", r)
		}
	}()
	b, err := os.ReadFile(path)
	if err != nil {
		return err
	}
	var p Pin
	if err := json.Unmarshal(b, &p); err != nil {
		return err
	}
	kind, _ := p["kind"].(string)
	fn, ok := kinds[kind]
	if !ok {
		return fmt.Errorf("unsupported kind %q", kind)
	}
	rel, _ := filepath.Rel(root, path)
	if cmd == "list" {
		fmt.Fprintf(stdout, "%-26s %-19s %-14s %s\n", name, kind, label(p), rel)
		return nil
	}
	latest, n, err := fn(p, cmd == "update")
	switch {
	case err != nil:
		return err
	case n == nil:
		fmt.Fprintf(stdout, "%-26s up to date  %s\n", name, latest)
	case cmd == "check":
		fmt.Fprintf(stdout, "%-26s OUTDATED    %s -> %s\n", name, label(p), latest)
	default:
		if err := writeAtomic(path, n); err != nil {
			return err
		}
		fmt.Fprintf(stdout, "%-26s UPDATED     %s -> %s  (%s)\n", name, label(p), latest, rel)
	}
	return nil
}

func run(args []string, stdout, stderr io.Writer) int {
	fl := flag.NewFlagSet("pins", flag.ContinueOnError)
	fl.SetOutput(stderr)
	fl.StringVar(&root, "root", ".", "repository root to scan for *.pin.json")
	if err := fl.Parse(args); err != nil {
		return 2
	}
	args = fl.Args()
	if len(args) == 0 || (args[0] != "list" && args[0] != "check" && args[0] != "update") {
		fmt.Fprintln(stderr, "usage: pins [-root DIR] list | check [NAME...] | update [NAME...]")
		return 2
	}
	cmd, names := args[0], args[1:]
	pins, err := discover(root)
	if err != nil {
		fmt.Fprintln(stderr, "error:", err)
		return 2
	}
	var unknown []string
	for _, n := range names {
		if _, ok := pins[n]; !ok {
			unknown = append(unknown, n)
		}
	}
	if len(unknown) > 0 {
		fmt.Fprintf(stderr, "unknown pin(s): %s; known: %s\n", strings.Join(unknown, ", "), strings.Join(sortedKeys(pins), ", "))
		return 2
	}
	if len(names) == 0 {
		names = sortedKeys(pins)
	}
	failed := 0
	for _, name := range names {
		if err := process(cmd, name, pins[name], stdout); err != nil {
			failed++
			fmt.Fprintf(stderr, "%-26s ERROR       %v\n", name, err)
		}
	}
	if failed > 0 {
		fmt.Fprintf(stderr, "%d pin(s) failed\n", failed)
		return 1
	}
	return 0
}

func main() { os.Exit(run(os.Args[1:], os.Stdout, os.Stderr)) }

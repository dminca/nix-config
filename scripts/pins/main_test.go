package main

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"slices"
	"strings"
	"sync"
	"testing"
	"time"
)

func rel(tag, published string, pre, draft bool, assets ...string) Release {
	r := Release{TagName: tag, PublishedAt: published, Prerelease: pre, Draft: draft}
	for _, a := range assets {
		r.Assets = append(r.Assets, struct {
			Name string `json:"name"`
		}{a})
	}
	return r
}

var releases = []Release{
	rel("v2.0.0-beta1", "2026-03-01T00:00:00Z", true, false, "app-2.0.0-beta1.dmg"),
	rel("v1.1.0", "2026-02-01T00:00:00Z", false, false, "app-1.1.0.dmg"),
	rel("v9.9.9", "2026-04-01T00:00:00Z", false, true),
	rel("other-v5.0.0", "2026-05-01T00:00:00Z", false, false, "other.dmg"),
	rel("v1.0.0", "2026-01-01T00:00:00Z", false, false, "app-1.0.0.dmg"),
}

func releasePin(version string) Pin {
	var p Pin
	_ = json.Unmarshal([]byte(`{"kind":"github-release","repo":"o/r","tagPrefix":"v","version":"`+version+`",
		"assets":{"aarch64-darwin":{"file":"app-{version}.dmg","url":"old","hash":"old"}}}`), &p)
	return p
}

func mustErr(t *testing.T, err error, want string) {
	t.Helper()
	if err == nil || !strings.Contains(err.Error(), want) {
		t.Fatalf("want error containing %q, got %v", want, err)
	}
}

func TestSelectRelease(t *testing.T) {
	for _, tc := range []struct {
		prefix string
		pre    bool
		want   string
	}{
		{"v", false, "v1.1.0"},             // skips prerelease, draft, other prefix
		{"v", true, "v2.0.0-beta1"},        // prerelease channel
		{"other-v", false, "other-v5.0.0"}, // monorepo tag prefix
	} {
		r, err := selectRelease(releases, tc.prefix, tc.pre)
		if err != nil || r.TagName != tc.want {
			t.Errorf("%q pre=%v: got %q, %v", tc.prefix, tc.pre, r.TagName, err)
		}
	}
	_, err := selectRelease(releases, "missing-", false)
	mustErr(t, err, "no stable release")
}

func TestReleaseTarget(t *testing.T) {
	v, n, err := releaseTarget(releasePin("1.0.0"), releases)
	if err != nil || v != "1.1.0" {
		t.Fatal(v, err)
	}
	a := n["assets"].(map[string]any)["aarch64-darwin"].(map[string]any)
	if a["url"] != "https://github.com/o/r/releases/download/v1.1.0/app-1.1.0.dmg" || a["file"] != "app-{version}.dmg" {
		t.Fatal(a)
	}

	p := releasePin("1.0.0")
	p["assets"].(map[string]any)["x86_64-linux"] = map[string]any{"file": "app-{version}.rpm"}
	_, _, err = releaseTarget(p, releases)
	mustErr(t, err, `no asset "app-1.1.0.rpm"`)

	_, _, err = releaseTarget(releasePin("2.0.0-beta1"), releases)
	mustErr(t, err, "refusing downgrade")
}

func TestVSCodeSkipsPrereleaseAndPlatformBuilds(t *testing.T) {
	var vs []vsVersion
	_ = json.Unmarshal([]byte(`[
		{"version":"0.9.0","properties":[{"key":"Microsoft.VisualStudio.Code.PreRelease","value":"true"}]},
		{"version":"0.8.0","targetPlatform":"darwin-arm64"},
		{"version":"0.7.4"}]`), &vs)
	if v, err := latestVSCodeVersion(vs); v != "0.7.4" || err != nil {
		t.Fatal(v, err)
	}
}

func TestSRIFromPrefixed(t *testing.T) {
	if got, _ := sriFromPrefixed("sha256:" + strings.Repeat("00", 32)); got != "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=" {
		t.Fatal(got)
	}
	_, err := sriFromPrefixed("sha256:3c85")
	mustErr(t, err, "unsupported upstream hash")
}

// fakeJSON serves canned responses by URL substring.
func fakeJSON(t *testing.T, responses map[string]string) {
	t.Helper()
	old := getJSON
	t.Cleanup(func() { getJSON = old })
	getJSON = func(url string, _ any, _ map[string]string, out any) error {
		for k, v := range responses {
			if strings.Contains(url, k) {
				return json.Unmarshal([]byte(v), out)
			}
		}
		return errors.New("unexpected request " + url)
	}
}

func TestAMOGuidMismatch(t *testing.T) {
	fakeJSON(t, map[string]string{"addons.mozilla.org": `{"guid":"evil@example","current_version":{"version":"2"}}`})
	_, _, err := amo(Pin{"slug": "x", "addonId": "good@example", "version": "1"}, false)
	mustErr(t, err, "guid")
}

func TestAMOHashMismatch(t *testing.T) {
	fakeJSON(t, map[string]string{"addons.mozilla.org": `{"guid":"a@b","current_version":{"version":"2","file":{"url":"u","hash":"sha256:` + strings.Repeat("00", 32) + `"}}}`})
	old := prefetchURL
	t.Cleanup(func() { prefetchURL = old })
	prefetchURL = func(string) (string, error) { return "sha256-other", nil }
	_, _, err := amo(Pin{"slug": "x", "addonId": "a@b", "version": "1"}, true)
	mustErr(t, err, "!= AMO hash")
}

func TestCommitDiverged(t *testing.T) {
	fakeJSON(t, map[string]string{
		"/commits/main": `{"sha":"` + strings.Repeat("b", 40) + `"}`,
		"/compare/":     `{"status":"diverged"}`,
	})
	_, _, err := githubCommit(Pin{"owner": "o", "repo": "r", "branch": "main", "rev": strings.Repeat("a", 40)}, true)
	mustErr(t, err, "diverged")
}

func TestCaddyPluginRecomputesHashForSameVersion(t *testing.T) {
	fakeJSON(t, map[string]string{"proxy.golang.org": `{"Version":"v1.1.0"}`})
	old := caddyHash
	t.Cleanup(func() { caddyHash = old })
	caddyHash = func(host, plugin string) (string, error) {
		if host != "h" || plugin != "github.com/x/y@v1.1.0" {
			t.Fatal(host, plugin)
		}
		return "sha256-new", nil
	}
	p := Pin{"module": "github.com/x/y", "version": "v1.1.0", "host": "h", "hash": "sha256-stale"}
	if _, n, _ := caddyPlugin(p, false); n != nil {
		t.Fatal("check must not report same version as outdated", n)
	}
	_, n, err := caddyPlugin(p, true)
	if err != nil || n["hash"] != "sha256-new" {
		t.Fatal(n, err)
	}
}

func TestGotHashParsing(t *testing.T) {
	m := gotHash.FindStringSubmatch("specified: sha256-AAAA\n            got:    sha256-CpfQSS+dWFNhnTfo9TEDyRnsMtZScvyL+5/4gd82pI0=\n")
	if m == nil || m[1] != "sha256-CpfQSS+dWFNhnTfo9TEDyRnsMtZScvyL+5/4gd82pI0=" {
		t.Fatal(m)
	}
}

// --- driver -----------------------------------------------------------------

func write(t *testing.T, dir, rel string, p any) string {
	t.Helper()
	path := filepath.Join(dir, rel)
	_ = os.MkdirAll(filepath.Dir(path), 0o755)
	b, _ := json.Marshal(p)
	if err := os.WriteFile(path, b, 0o644); err != nil {
		t.Fatal(err)
	}
	return path
}

func stubReleases(t *testing.T, prefetch func(string) (string, error)) {
	t.Helper()
	b, _ := json.Marshal(releases)
	old, oldP := getJSON, prefetchURL
	t.Cleanup(func() { getJSON, prefetchURL = old, oldP })
	getJSON = func(url string, _ any, _ map[string]string, out any) error {
		if strings.Contains(url, "page=1") {
			return json.Unmarshal(b, out)
		}
		return json.Unmarshal([]byte("[]"), out)
	}
	prefetchURL = prefetch
}

func runIn(dir string, args ...string) int {
	return run(append([]string{"-root", dir}, args...), io.Discard, io.Discard)
}

func TestUpdateRewritesVersionURLAndHash(t *testing.T) {
	dir := t.TempDir()
	path := write(t, dir, "a/app.pin.json", releasePin("1.0.0"))
	stubReleases(t, func(string) (string, error) { return "sha256-new", nil })
	if rc := runIn(dir, "update", "app"); rc != 0 {
		t.Fatal(rc)
	}
	var p Pin
	b, _ := os.ReadFile(path)
	_ = json.Unmarshal(b, &p)
	a := p["assets"].(map[string]any)["aarch64-darwin"].(map[string]any)
	if p["version"] != "1.1.0" || a["hash"] != "sha256-new" || !strings.HasSuffix(a["url"].(string), "/v1.1.0/app-1.1.0.dmg") {
		t.Fatal(p)
	}
}

func TestFailuresLeaveFileUntouched(t *testing.T) {
	for name, prefetch := range map[string]func(string) (string, error){
		"hash": func(string) (string, error) { return "", errors.New("download failed") },
	} {
		dir := t.TempDir()
		path := write(t, dir, "a/app.pin.json", releasePin("1.0.0"))
		before, _ := os.ReadFile(path)
		stubReleases(t, prefetch)
		if rc := runIn(dir, "update"); rc != 1 {
			t.Fatal(name, rc)
		}
		if after, _ := os.ReadFile(path); string(after) != string(before) {
			t.Fatal(name, "file changed")
		}
	}
	dir := t.TempDir()
	path := write(t, dir, "a/app.pin.json", releasePin("1.0.0"))
	before, _ := os.ReadFile(path)
	fakeJSON(t, map[string]string{}) // every request fails
	if rc := runIn(dir, "update"); rc != 1 {
		t.Fatal(rc)
	}
	if after, _ := os.ReadFile(path); string(after) != string(before) {
		t.Fatal("file changed on lookup failure")
	}
}

func TestCheckNeverWritesOrHashesAnyPinKind(t *testing.T) {
	dir := t.TempDir()
	paths := []string{
		write(t, dir, "app.pin.json", releasePin("1.0.0")),
		writeAMOPin(t, dir, "addon", "1"),
		write(t, dir, "commit.pin.json", Pin{
			"kind": "github-commit", "owner": "o", "repo": "r", "branch": "main",
			"rev": strings.Repeat("a", 40), "hash": "old",
		}),
		write(t, dir, "extension.pin.json", Pin{
			"kind": "vscode-marketplace", "publisher": "test", "name": "extension",
			"version": "1", "hash": "old",
		}),
		write(t, dir, "plugin.pin.json", Pin{
			"kind": "caddy-plugin", "module": "github.com/test/plugin",
			"version": "v1", "host": "test-host", "hash": "old",
		}),
	}
	before := make(map[string][]byte)
	for _, path := range paths {
		content, err := os.ReadFile(path)
		if err != nil {
			t.Fatal(err)
		}
		before[path] = content
	}
	releaseJSON, err := json.Marshal(releases)
	if err != nil {
		t.Fatal(err)
	}
	fakeJSON(t, map[string]string{
		"/releases?per_page=100&page=1": string(releaseJSON),
		"/releases?per_page=100&page=2": "[]",
		"/commits/main":                 `{"sha":"` + strings.Repeat("b", 40) + `"}`,
		"/compare/":                     `{"status":"ahead"}`,
		"/addon/addon/":                 `{"guid":"test@example","current_version":{"version":"2"}}`,
		"/extensionquery":               `{"results":[{"extensions":[{"versions":[{"version":"2"}]}]}]}`,
		"proxy.golang.org":              `{"Version":"v2"}`,
	})
	unexpectedHash := func(string) (string, error) {
		t.Error("check must not fetch artifacts or calculate hashes")
		return "", errors.New("unexpected hash calculation")
	}
	oldURL, oldGitHub, oldCaddy := prefetchURL, prefetchGitHub, caddyHash
	t.Cleanup(func() { prefetchURL, prefetchGitHub, caddyHash = oldURL, oldGitHub, oldCaddy })
	prefetchURL = unexpectedHash
	prefetchGitHub = func(_, _, _ string) (string, error) { return unexpectedHash("") }
	caddyHash = func(_, _ string) (string, error) { return unexpectedHash("") }

	var stdout, stderr bytes.Buffer
	if exitCode := run([]string{"-root", dir, "check"}, &stdout, &stderr); exitCode != 0 {
		t.Fatalf("check exited %d: %s", exitCode, &stderr)
	}
	if count := strings.Count(stdout.String(), "OUTDATED"); count != len(paths) {
		t.Errorf("reported %d outdated pins; want all %d", count, len(paths))
	}
	for _, path := range paths {
		after, err := os.ReadFile(path)
		if err != nil || !bytes.Equal(after, before[path]) {
			t.Errorf("check changed pin %s or made it unreadable: %v", path, err)
		}
	}
}

func TestCheckWithNoPinsSucceedsWithoutOutput(t *testing.T) {
	var stdout, stderr bytes.Buffer
	exitCode := run([]string{"-root", t.TempDir(), "check"}, &stdout, &stderr)
	if exitCode != 0 || stdout.Len() != 0 || stderr.Len() != 0 {
		t.Errorf("empty check: exit %d, stdout %q, stderr %q; want success without output", exitCode, &stdout, &stderr)
	}
}

func writeAMOPin(t *testing.T, dir, name, version string) string {
	t.Helper()
	return write(t, dir, name+".pin.json", Pin{
		"kind": "amo", "slug": name, "addonId": "test@example",
		"version": version, "url": "old", "hash": "old",
	})
}

func TestCheckRunsFourLookupsAtOnceAndFinishesQueuedPins(t *testing.T) {
	dir := t.TempDir()
	const pinCount = 12
	for index := range pinCount {
		writeAMOPin(t, dir, fmt.Sprintf("pin-%02d", index), "2")
	}

	var mutex sync.Mutex
	active, peak, started := 0, 0, 0
	firstBatchReady := make(chan struct{})
	var releaseOnce sync.Once
	t.Cleanup(func() { releaseOnce.Do(func() { close(firstBatchReady) }) })

	old := getJSON
	t.Cleanup(func() { getJSON = old })
	getJSON = func(_ string, _ any, _ map[string]string, out any) error {
		mutex.Lock()
		active++
		started++
		peak = max(peak, active)
		// Hold the first requests until four have started, proving overlap.
		if started == 4 {
			releaseOnce.Do(func() { close(firstBatchReady) })
		}
		mutex.Unlock()
		defer func() {
			mutex.Lock()
			active--
			mutex.Unlock()
		}()

		select {
		case <-firstBatchReady:
		case <-time.After(5 * time.Second):
			releaseOnce.Do(func() { close(firstBatchReady) })
			return errors.New("four concurrent lookups did not start")
		}
		return json.Unmarshal([]byte(`{"guid":"test@example","current_version":{"version":"2"}}`), out)
	}

	var stdout, stderr bytes.Buffer
	exitCode := run([]string{"-root", dir, "check"}, &stdout, &stderr)
	if exitCode != 0 {
		t.Fatalf("check exited %d: %s", exitCode, &stderr)
	}
	if peak != 4 {
		t.Errorf("peak concurrent lookups = %d; want exactly 4", peak)
	}
	if started != pinCount || active != 0 {
		t.Errorf("started = %d, active = %d; want %d completed lookups", started, active, pinCount)
	}
	if lines := strings.Count(stdout.String(), "\n"); lines != pinCount {
		t.Errorf("reported %d pins; want %d", lines, pinCount)
	}
}

func TestCheckPreservesOutputOrderWhenLookupsFinishOutOfOrder(t *testing.T) {
	for _, test := range []struct {
		name     string
		selected []string
		want     []string
	}{
		{name: "alphabetical", want: []string{"alpha", "beta", "gamma"}},
		{name: "one selected name", selected: []string{"gamma"}, want: []string{"gamma"}},
		{name: "selected subset", selected: []string{"alpha", "gamma"}, want: []string{"alpha", "gamma"}},
		{
			name:     "selected names including duplicates",
			selected: []string{"alpha", "gamma", "beta", "alpha"},
			want:     []string{"alpha", "gamma", "beta", "alpha"},
		},
	} {
		t.Run(test.name, func(t *testing.T) {
			dir := t.TempDir()
			paths := make(map[string]string)
			before := make(map[string][]byte)
			for _, name := range []string{"alpha", "beta", "gamma"} {
				paths[name] = writeAMOPin(t, dir, name, "1")
				before[name], _ = os.ReadFile(paths[name])
			}

			gammaFinished := make(chan struct{})
			var releaseOnce sync.Once
			t.Cleanup(func() { releaseOnce.Do(func() { close(gammaFinished) }) })
			old := getJSON
			t.Cleanup(func() { getJSON = old })
			getJSON = func(url string, _ any, _ map[string]string, out any) error {
				// Alpha is first in the output but must finish after gamma.
				if strings.Contains(url, "/alpha/") {
					select {
					case <-gammaFinished:
					case <-time.After(5 * time.Second):
						return errors.New("gamma lookup did not finish before alpha")
					}
				}
				err := json.Unmarshal([]byte(`{"guid":"test@example","current_version":{"version":"2"}}`), out)
				if strings.Contains(url, "/gamma/") {
					releaseOnce.Do(func() { close(gammaFinished) })
				}
				return err
			}

			var stdout, stderr bytes.Buffer
			args := append([]string{"-root", dir, "check"}, test.selected...)
			if exitCode := run(args, &stdout, &stderr); exitCode != 0 {
				t.Fatalf("check exited %d: %s", exitCode, &stderr)
			}
			var expected bytes.Buffer
			for _, name := range test.want {
				fmt.Fprintf(&expected, "%-26s OUTDATED    1 -> 2\n", name)
			}
			if stdout.String() != expected.String() || stderr.Len() != 0 {
				t.Errorf("unexpected report:\nstdout: %q\nstderr: %q\nwant: %q", &stdout, &stderr, &expected)
			}
			for name, path := range paths {
				after, err := os.ReadFile(path)
				if err != nil || !bytes.Equal(after, before[name]) {
					t.Errorf("check changed pin %s or made it unreadable: %v", name, err)
				}
			}
		})
	}
}

func TestCheckReportsEveryFailureAndContinuesWithOtherPins(t *testing.T) {
	dir := t.TempDir()
	write(t, dir, "invalid.pin.json", Pin{"kind": "mystery"})
	writeAMOPin(t, dir, "unreachable", "1")
	writeAMOPin(t, dir, "current", "2")
	writeAMOPin(t, dir, "outdated", "1")
	fakeJSON(t, map[string]string{
		"/current/":  `{"guid":"test@example","current_version":{"version":"2"}}`,
		"/outdated/": `{"guid":"test@example","current_version":{"version":"2"}}`,
	})

	var stdout, stderr bytes.Buffer
	exitCode := run([]string{"-root", dir, "check"}, &stdout, &stderr)
	if exitCode != 1 {
		t.Errorf("check exited %d; want 1 for failed lookups", exitCode)
	}
	expectedOutput := fmt.Sprintf("%-26s up to date  2\n%-26s OUTDATED    1 -> 2\n", "current", "outdated")
	if stdout.String() != expectedOutput {
		t.Errorf("successful pins were not reported correctly: %q", &stdout)
	}
	expectedErrors := fmt.Sprintf("%-26s ERROR       unsupported kind %q\n", "invalid", "mystery") +
		fmt.Sprintf("%-26s ERROR       unexpected request https://addons.mozilla.org/api/v5/addons/addon/unreachable/\n", "unreachable") +
		"2 pin(s) failed\n"
	if stderr.String() != expectedErrors {
		t.Errorf("errors = %q; want %q", &stderr, expectedErrors)
	}
}

func TestListAndUpdateKeepSequentialBehavior(t *testing.T) {
	dir := t.TempDir()
	writeAMOPin(t, dir, "beta", "1")
	writeAMOPin(t, dir, "alpha", "1")

	var mutex sync.Mutex
	var events []string
	oldJSON, oldPrefetch := getJSON, prefetchURL
	t.Cleanup(func() { getJSON, prefetchURL = oldJSON, oldPrefetch })
	getJSON = func(url string, _ any, _ map[string]string, out any) error {
		mutex.Lock()
		events = append(events, "lookup "+url)
		mutex.Unlock()
		return json.Unmarshal([]byte(`{"guid":"test@example","current_version":{"version":"2","file":{"url":"asset","hash":"sha256:`+strings.Repeat("00", 32)+`"}}}`), out)
	}
	prefetchURL = func(url string) (string, error) {
		mutex.Lock()
		events = append(events, "hash "+url)
		mutex.Unlock()
		return sriFromPrefixed("sha256:" + strings.Repeat("00", 32))
	}

	var stdout, stderr bytes.Buffer
	if exitCode := run([]string{"-root", dir, "list"}, &stdout, &stderr); exitCode != 0 {
		t.Fatalf("list exited %d: %s", exitCode, &stderr)
	}
	expectedList := fmt.Sprintf("%-26s %-19s %-14s alpha.pin.json\n", "alpha", "amo", "1") +
		fmt.Sprintf("%-26s %-19s %-14s beta.pin.json\n", "beta", "amo", "1")
	if stdout.String() != expectedList || len(events) != 0 {
		t.Errorf("list must stay ordered and offline: output %q, requests %v", &stdout, events)
	}

	if exitCode := run([]string{"-root", dir, "update"}, &stdout, &stderr); exitCode != 0 {
		t.Fatalf("update exited %d: %s", exitCode, &stderr)
	}
	expectedEvents := []string{
		"lookup https://addons.mozilla.org/api/v5/addons/addon/alpha/",
		"hash asset",
		"lookup https://addons.mozilla.org/api/v5/addons/addon/beta/",
		"hash asset",
	}
	if !slices.Equal(events, expectedEvents) {
		t.Errorf("update must finish each pin before starting the next: got %v; want %v", events, expectedEvents)
	}
}

func TestBadInputs(t *testing.T) {
	dir := t.TempDir()
	write(t, dir, "a/x.pin.json", Pin{"kind": "mystery"})
	write(t, dir, "a/y.pin.json", Pin{"kind": "github-release"}) // missing fields
	if rc := runIn(dir, "check"); rc != 1 {
		t.Fatal("unsupported kind / missing field:", rc)
	}
	if rc := runIn(dir, "check", "nope"); rc != 2 {
		t.Fatal("unknown name:", rc)
	}
	write(t, dir, "b/x.pin.json", Pin{})
	if rc := runIn(dir, "list"); rc != 2 {
		t.Fatal("duplicate name:", rc)
	}
}

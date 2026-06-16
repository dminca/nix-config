# Enable Nextcloud Office

Diataxis type: How-to guide

Use this guide to enable Nextcloud Office by deploying Collabora Online Development Edition (CODE).

## Prerequisite

- A working Nextcloud deployment.
- Reachability between Nextcloud and Collabora CODE service.

## Steps

1. Deploy Collabora CODE in your NixOS configuration.
2. Rebuild the host and verify the CODE endpoint is reachable.
3. Enable and configure Nextcloud Office app to use the CODE endpoint.
4. Validate by opening or creating a document in Nextcloud.

## Reference implementation

- Collabora + Nextcloud on NixOS: [setup walkthrough][blog]

[blog]: https://diogotc.com/blog/collabora-nextcloud-nixos/

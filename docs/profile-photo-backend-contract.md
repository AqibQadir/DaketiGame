# Profile photo upload: proposed backend contract

Status: proposal only. The supplied API guide has no photo upload endpoint or avatar field, and no backend repository is available in this workspace. These routes are not implemented or called by the app. Confirm an existing contract or implement this proposal before connecting photo upload.

## Required server behavior

- An authenticated multipart upload endpoint, proposed as `POST /api/auth/me/avatar`, with a file field named `avatar`.
- Accept JPEG/PNG/WebP images up to an agreed limit (proposed: 5 MB). Validate actual image content, resize/re-encode, and strip metadata on the server.
- Store the image in persistent object storage and save its URL against the authenticated user; never accept a client-supplied account ID to select whose avatar to change.
- Return `{ "success": true, "user": { ...existingUserFields, "avatarUrl": "https://..." } }` only after storage and profile update succeed. Use a versioned URL so replacing a photo refreshes cached images.
- Include nullable `avatarUrl` in login/signup/Facebook/current-user/profile-update responses. Include it in game player data if other players should see account photos.
- Proposed removal endpoint: `DELETE /api/auth/me/avatar`, returning the updated user with `avatarUrl: null`.
- Preserve the old photo if upload fails. Return normal JSON errors for authentication, invalid file, oversized upload and storage failure.

## App work once the contract is confirmed

1. Add a gallery picker and image preview with Replace/Cancel controls.
2. Upload the selected image using the authenticated account session; show progress and retry, and retain the old photo on failure.
3. Parse the returned avatar URL, update the profile from the server response, and reload it on the next sign-in/device.
4. Show a fallback avatar when no URL is present or image loading fails.
5. Test selection cancellation, oversized/invalid images, expired session, failed upload, replacement, account switching and app restart.

## Account changes completed separately

Name and optional date of birth save through the existing PATCH /api/auth/me endpoint. The editing dialog validates input, prevents duplicate requests, retains rejected edits and confirms success. Missing-email accounts can use the existing attempted email update; the app reports if the backend ignores it, as the guide is contradictory on this capability.

Account Options exposes password update with confirmation, password-reset email (including password setup for Facebook-only accounts), resend verification, and email/Facebook connection status. Existing email changes, provider unlinking and account deletion require separate documented backend contracts and are not represented as working features.

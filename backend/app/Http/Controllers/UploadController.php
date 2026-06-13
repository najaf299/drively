<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

/**
 * Generic authenticated image upload.
 *
 * The whole app stores images as URLs — car photos (`photos.*.url`), KYC docs
 * (`front_url`/`back_url`/`selfie_url`), chat images (`image_url`) and trip
 * inspection shots (`photo_urls`) all expect a pre-uploaded link. The client
 * uploads here first, then sends the returned URL to the relevant endpoint.
 *
 * Files land on the `public` disk; the URL is built from the *request host*
 * (not APP_URL) so a phone reaching the Mac over the LAN gets a reachable link,
 * exactly like ProfileController::uploadAvatar.
 */
class UploadController extends Controller
{
    /** Folders the client may upload into (keeps storage tidy + predictable). */
    private const FOLDERS = ['car_photos', 'kyc', 'chat', 'trips', 'misc'];

    public function store(Request $request): JsonResponse
    {
        $request->validate([
            'file' => ['required', 'image', 'mimes:jpg,jpeg,png,webp', 'max:8192'],
            'folder' => ['nullable', 'string'],
        ]);

        $folder = in_array($request->input('folder'), self::FOLDERS, true)
            ? $request->input('folder')
            : 'misc';

        $path = $request->file('file')->store($folder, 'public');
        $url = $request->getSchemeAndHttpHost() . Storage::url($path);

        return $this->success(['url' => $url], 'Uploaded', 201);
    }
}

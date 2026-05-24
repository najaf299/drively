package com.example.app

import io.flutter.embedding.android.FlutterFragmentActivity

// FlutterFragmentActivity (not FlutterActivity) is required by flutter_stripe's
// Payment Sheet, which presents itself as a fragment.
class MainActivity : FlutterFragmentActivity()

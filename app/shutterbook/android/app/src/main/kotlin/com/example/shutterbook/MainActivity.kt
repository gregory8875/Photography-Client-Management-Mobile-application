package com.example.shutterbook

import android.os.Bundle
import android.util.Log
import androidx.fragment.app.FragmentActivity
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity() {
	override fun onCreate(savedInstanceState: Bundle?) {
		super.onCreate(savedInstanceState)
		Log.i("MainActivity", "runtime class=${this::class.java.name} isFragmentActivity=${this is FragmentActivity}")
	}
}

package com.epam.wristforce

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable


class MainActivity : ComponentActivity() {
    private lateinit var viewModel: VoiceViewModel

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        viewModel = VoiceViewModel(applicationContext)

        setContent {
            AppTheme(darkTheme = true) {
                VoiceAssistantScreen(viewModel = viewModel, applicationContext)
            }
        }
    }

    override fun onDestroy() {
        super.onDestroy()
    }
}

@Composable
fun AppTheme(
    darkTheme: Boolean = true, // Force dark theme
    content: @Composable () -> Unit
) {
    val colors = DarkColors // Always use the dark color scheme
    MaterialTheme(
        colorScheme = colors,
        typography = androidx.compose.material3.Typography(),
        content = content
    )
}

// Define the Dark Color Scheme
private val DarkColors = darkColorScheme(
    primary = androidx.compose.ui.graphics.Color(0xFF63C4FF),
    onPrimary = androidx.compose.ui.graphics.Color.Black,
    background = androidx.compose.ui.graphics.Color(0xFF0E0E0E),
    onBackground = androidx.compose.ui.graphics.Color.White,
    surface = androidx.compose.ui.graphics.Color(0xFF1C1C1C),
    onSurface = androidx.compose.ui.graphics.Color.White,
)
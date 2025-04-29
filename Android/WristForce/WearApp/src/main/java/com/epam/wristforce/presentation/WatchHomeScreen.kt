package com.epam.wristforce.presentation

import android.content.Context
import android.util.Log
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Divider
import androidx.compose.material3.ElevatedCard
import androidx.compose.material3.IconButton
import androidx.compose.material3.Surface
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.wear.compose.material.*
import com.epam.wristforce.R
import com.google.android.gms.wearable.DataEvent
import com.google.android.gms.wearable.DataMapItem
import com.google.android.gms.wearable.Wearable
import kotlinx.coroutines.delay
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

@Composable
fun WatchHomeScreen(context: Context,viewModel: WatchViewModel = remember { WatchViewModel(context) }) { // States to control screens
    var showMeetings by remember { mutableStateOf(false) }
    var showApprovals by remember { mutableStateOf(false) }
    var meetingsList by remember { mutableStateOf<List<String>>(emptyList()) } // Keeps the backend response

    Surface(
        modifier = Modifier.fillMaxSize(),
        color = Color(0xFF121212) // Consistent dark background
    ) {
        when {
            // Navigate to Meetings screen
            showMeetings -> {
                MeetingsScreen(
                    onBackClick = { showMeetings = false },
                    meetings = meetingsList
                )
            }
            // Navigate to Approvals screen
            showApprovals -> {
                ApprovalsScreen(
                    onBackClick = { showApprovals = false },
                    viewModel = viewModel
                )
            }
            // Default Home Screen
            else -> {
                HomeScreen(
                    context = context,
                    onMeetingsClick = {
                        // Send command to mobile
                        sendCommandToPhone(context, "meeting")

                        // Listen for response
                        Wearable.getDataClient(context).addListener { dataEvents ->
                            for (event in dataEvents) {
                                if (event.type == DataEvent.TYPE_CHANGED &&
                                    event.dataItem.uri.path == "/meetings_response"
                                ) {
                                    val dataMap = DataMapItem.fromDataItem(event.dataItem).dataMap
                                    val meetingsMessage = dataMap.getString("meetings_result") ?: "No data"
                                    meetingsList = meetingsMessage.split(", ").map { it.trim() } // Parse response data
                                    showMeetings = true // Show the Meetings Screen
                                }
                            }
                        }
                    },
                    onApprovalsClick = { showApprovals = true }
                )
            }
        }
    }
}

// Home Screen with Action Buttons
@Composable
private fun HomeScreen(
    context: Context,
    onMeetingsClick: () -> Unit,
    onApprovalsClick: () -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(8.dp),
        verticalArrangement = Arrangement.SpaceBetween
    ) {
        // Time Display
        TimeDisplay( modifier = Modifier.padding(top = 8.dp, bottom = 10.dp))
        // Main action buttons ("Tap to Speak" and "Tap to Read")
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceEvenly
            ) {
                // "Tap to Speak" Button
                ActionButton(
                    iconRes = R.drawable.hold_to_speak,
                    label = "Tap to Speak",
                    buttonColors = ButtonDefaults.iconButtonColors(),
                    onClick = { sendCommandToPhone(context, "listen") },
                    iconSize = 48.dp,
                    isPrimary = true
                )
            }
        }

// Quick Action Buttons (Dummy for now)
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(bottom = 20.dp),
            horizontalArrangement = Arrangement.SpaceEvenly
        ) {
            ActionButton(
                iconRes = R.drawable.meeting,
                label = "Meetings",
                buttonColors = ButtonDefaults.iconButtonColors(),
                onClick = onMeetingsClick,
                iconSize = 38.dp
            )
            ActionButton(
                iconRes = R.drawable.approvals,
                label = "Approvals",
                buttonColors = ButtonDefaults.iconButtonColors(),
                onClick = onApprovalsClick,
                iconSize = 38.dp
            )
            ActionButton(
                iconRes = R.drawable.slack,
                label = "Slack",
                buttonColors = ButtonDefaults.iconButtonColors(),
                onClick = { /* Dummy */ },
                iconSize = 38.dp
            )
        }
        Spacer(modifier = Modifier.height(4.dp))
    }
}

@Composable
fun ActionButton(
    iconRes: Int,
    label: String,
    buttonColors: ButtonColors,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    iconSize: Dp = 24.dp, // Default size
    isPrimary: Boolean = false // Flag for primary styling
) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Button(
            onClick = onClick,
            modifier = Modifier.size(50.dp),
            colors = buttonColors
        ) {
            Icon(
                painter = painterResource(id = iconRes),
                contentDescription = label,
                modifier = Modifier.size(iconSize),
                tint = Color.Unspecified
            )
        }
        Text(
            text = label,
            color = Color.White,
            fontSize = if (isPrimary) 12.sp else 10.sp,
            modifier = Modifier.padding(top = if (isPrimary) 4.dp else 0.dp)
        )
    }
}



// Meetings Screen
@Composable
fun MeetingsScreen(onBackClick: () -> Unit, meetings: List<String>) {
    Surface(
        modifier = Modifier.fillMaxSize(),
        color = Color(0xFF121212)
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(10.dp),
            verticalArrangement = Arrangement.SpaceBetween,
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            // Back Button
            Row(
                verticalAlignment = Alignment.CenterVertically,
                modifier = Modifier.fillMaxWidth()
            ) {
                IconButton(
                    onClick = onBackClick,
                    modifier = Modifier.padding(5.dp)
                ) {
                    Icon(
                        imageVector = Icons.Filled.ArrowBack,
                        contentDescription = "Back",
                        tint = Color.White,
                        modifier = Modifier.size(15.dp)
                    )
                }
                Text(
                    text = "Meetings Today",
                    color = Color.White,
                    fontSize = 15.sp,
                    fontWeight = FontWeight.Medium,
                    modifier = Modifier.padding(start = 0.dp)
                )
            }

            // List of meetings
            LazyColumn(
                modifier = Modifier.fillMaxSize(),
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                items(meetings) { meeting ->
                    MeetingCard(meeting = meeting)
                }
            }
        }
    }
}

// Meeting Card
@Composable
fun MeetingCard(meeting: String) {
    ElevatedCard(
        modifier = Modifier.fillMaxWidth(),
        elevation = CardDefaults.elevatedCardElevation(1.dp),
        colors = CardDefaults.cardColors(containerColor = Color(0xFF2D2D2D))
    ) {
        Column(
            modifier = Modifier.padding(5.dp),
            verticalArrangement = Arrangement.Center,
            horizontalAlignment = Alignment.Start
        ) {
            Text(
                text = meeting,
                color = Color.White,
                fontSize = 12.sp,
                fontWeight = FontWeight.Medium
            )
        }
    }
}

@Composable
fun ApprovalCard(approval: String) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clickable { /* Handle click logic here */ }
            .padding(horizontal = 0.dp, vertical = 6.dp)
    ) {
        Text(
            text = approval,
            color = Color.White,
            fontSize = 12.sp,
            fontWeight = FontWeight.Medium,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
            modifier = Modifier.padding(bottom = 4.dp)
        )

        Row(
            horizontalArrangement = Arrangement.SpaceBetween,
            modifier = Modifier.fillMaxWidth()
        ) {
            // Accept Button
            IconButton(
                onClick = { /* Add Accept Logic Here */ },
                modifier = Modifier.size(25.dp)
            ) {
                Icon(
                    painter = painterResource(id = R.drawable.approval_accept),
                    contentDescription = "Accept",
                    tint = Color.Unspecified,
                    modifier = Modifier.size(22.dp)
                )
            }

            // Later Button
            IconButton(
                onClick = { /* Add Later Logic Here */ },
                modifier = Modifier.size(25.dp)
            ) {
                Icon(
                    painter = painterResource(id = R.drawable.approval_later),
                    contentDescription = "Later",
                    tint = Color.Unspecified,
                    modifier = Modifier.size(22.dp)
                )
            }

            // Reject Button
            IconButton(
                onClick = { /* Add Reject Logic Here */ },
                modifier = Modifier.size(25.dp)
            ) {
                Icon(
                    painter = painterResource(id = R.drawable.approval_reject),
                    contentDescription = "Decline",
                    tint = Color.Unspecified,
                    modifier = Modifier.size(22.dp)
                )
            }
        }

        // Divider between items
        Divider(
            color = Color(0xFF444444),
            thickness = 0.5.dp,
            modifier = Modifier.padding(top = 4.dp)
        )
    }
}

@Composable
fun ApprovalsScreen(
    onBackClick: () -> Unit,
    viewModel: WatchViewModel
) {
    val approvals by viewModel.approvals
    val isLoading by viewModel.isLoading
    val error by viewModel.error

    // Request approvals when screen first loads
    LaunchedEffect(Unit) {
        Log.d("ApprovalsScreen", "Screen launched - requesting approvals")
        viewModel.requestApprovalsFromMobile()
    }

    Surface(
        modifier = Modifier.fillMaxSize(),
        color = Color(0xFF121212)
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(10.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            // Header
            Row(
                verticalAlignment = Alignment.CenterVertically,
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(start = 18.dp, top = 10.dp, bottom = 8.dp)
            ) {
                IconButton(onClick = onBackClick) {
                    Icon(Icons.Default.ArrowBack, "Back", tint = Color.White)
                }
                Text(
                    text = "Approvals",
                    color = Color.White,
                    fontSize = 16.sp,
                    fontWeight = FontWeight.Bold,
                    modifier = Modifier.padding(start = 10.dp)
                )
            }

            when {
                isLoading -> {
                    Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                        CircularProgressIndicator()
                    }
                }
                error != null -> {
                    Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                        Text(text = error!!, color = Color.Red)
                    }
                }
                approvals.isEmpty() -> {
                    Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                        Text(text = "No approvals available", color = Color.LightGray)
                    }
                }
                else -> {
                    LazyColumn(
                        modifier = Modifier.fillMaxSize(),
                        contentPadding = PaddingValues(bottom = 8.dp)
                    ) {
                        items(approvals) { approval ->
                            ApprovalCard(approval)
                        }
                    }
                }
            }
        }
    }
}


// Time Display
@Composable
fun TimeDisplay(modifier: Modifier=Modifier) {
    var currentTime by remember { mutableStateOf(getCurrentTime()) }
    LaunchedEffect(Unit) {
        while (true) {
            delay(60_000L) // Update every minute
            currentTime = getCurrentTime()
        }
    }
    Text(
        text = currentTime,
        color = Color.White,
        fontSize = 20.sp,
        fontWeight = FontWeight.Medium,
        modifier = Modifier
            .fillMaxWidth()
            .padding(top = 5.dp, bottom = 4.dp),
        textAlign = TextAlign.Center
    )
}

// Get Current Time
private fun getCurrentTime(): String {
    val timeFormat = SimpleDateFormat("h:mm a", Locale.getDefault())
    return timeFormat.format(Date())
}


// Send Command to Phone
private fun sendCommandToPhone(context: Context, command: String) {
    val dataClient = com.google.android.gms.wearable.Wearable.getDataClient(context)
    val request = com.google.android.gms.wearable.PutDataMapRequest.create("/voice_command").run {
        dataMap.putString("command", command)
        dataMap.putLong("timestamp", System.currentTimeMillis())
        asPutDataRequest().setUrgent()
    }
    Thread {
        try {
            dataClient.putDataItem(request)
        } catch (e: Exception) {
            android.util.Log.e("WearApp", "Command send failed", e)
        }
    }.start()
}
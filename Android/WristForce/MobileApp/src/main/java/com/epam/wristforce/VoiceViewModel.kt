package com.epam.wristforce

import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import android.speech.tts.TextToSpeech
import android.util.Log
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.epam.wristforce.network.Conversation
import com.epam.wristforce.network.ConversationMessageRequest
import com.epam.wristforce.network.RetrofitClient
import com.google.android.gms.wearable.DataClient
import com.google.android.gms.wearable.DataEvent
import com.google.android.gms.wearable.DataEventBuffer
import com.google.android.gms.wearable.DataMapItem
import com.google.android.gms.wearable.PutDataMapRequest
import com.google.android.gms.wearable.Wearable
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

class VoiceViewModel(private val context: Context) : ViewModel(), DataClient.OnDataChangedListener {
    var ttsText = mutableStateOf("") // Text to be spoken by TTS
    var sttResult = mutableStateOf("") // Text from speech-to-text
    var isSpeaking = mutableStateOf(false)
    var isListening = mutableStateOf(false)
    var reportAction by mutableStateOf("No action received")
    var sessionId: String? = null // Session ID for the conversation
    private var sequenceId = 1

    private var recognizer: SpeechRecognizer? = null
    private var tts: TextToSpeech? = null
    private val dataClient: DataClient = Wearable.getDataClient(context)

    init {
        initializeTTS()
        dataClient.addListener(this)
        initializeSession() // Fetch the session ID when ViewModel is created
    }

    private fun initializeTTS() {
        tts = TextToSpeech(context) { status ->
            if (status != TextToSpeech.SUCCESS) {
                ttsText.value = "TTS Initialization Failed"
            }
        }
    }

    private fun initializeSession() {
        // Fetch session ID from the backend
        viewModelScope.launch(Dispatchers.IO) {
            try {
                val userId = "12345"
                val response = RetrofitClient.api.startConversation(Conversation(userId))
                if (response.isSuccessful) {
                    sessionId = response.body()?.sessionId
                } else {
                    // Handle failure
                    sttResult.value = "Failed to fetch session ID: ${response.errorBody()?.string()}"
                }
            } catch (e: Exception) {
                sttResult.value = "Error initializing session: ${e.message}"
            }
        }
    }

    fun speechToText() {
        if (context.hasRecordAudioPermission()) {
            recognizer = SpeechRecognizer.createSpeechRecognizer(context).apply {
                setRecognitionListener(object : RecognitionListener {
                    override fun onReadyForSpeech(params: Bundle?) {
                        sttResult.value = "Ready for Speech..."
                    }

                    override fun onBeginningOfSpeech() {
                        sttResult.value = "Listening..."
                        isListening.value = true
                    }

                    override fun onRmsChanged(rmsdB: Float) {}

                    override fun onBufferReceived(buffer: ByteArray?) {}

                    override fun onEndOfSpeech() {
                        sttResult.value = "Processing Speech..."
                        isListening.value = false
                    }

                    override fun onError(error: Int) {
                        sttResult.value = when (error) {
                            SpeechRecognizer.ERROR_AUDIO -> "Audio Recording Error"
                            SpeechRecognizer.ERROR_CLIENT -> "Client Side Error"
                            SpeechRecognizer.ERROR_INSUFFICIENT_PERMISSIONS -> "Insufficient Permissions"
                            SpeechRecognizer.ERROR_NETWORK -> "Network Error"
                            SpeechRecognizer.ERROR_NETWORK_TIMEOUT -> "Network Timeout"
                            SpeechRecognizer.ERROR_NO_MATCH -> "No Speech Recognized"
                            SpeechRecognizer.ERROR_RECOGNIZER_BUSY -> "Recognizer Busy"
                            SpeechRecognizer.ERROR_SERVER -> "Server Error"
                            SpeechRecognizer.ERROR_SPEECH_TIMEOUT -> "No Speech Input"
                            else -> "Unknown Error: $error"
                        }
                    }

                    override fun onResults(results: Bundle?) {
                        results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                            ?.firstOrNull()
                            ?.let { result ->
                                sttResult.value = result
                                sendToBackend(result) // Send the text to the backend
                            }
                    }

                    override fun onPartialResults(partialResults: Bundle?) {}

                    override fun onEvent(eventType: Int, params: Bundle?) {}
                })

                startListening(Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
                    putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
                    putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, false)
                })
            }
        } else {
            sttResult.value = "Microphone permission not granted"
        }
    }


    private fun meetingsToday() {
        val predefinedMessage = "What are meetings present today?" // Request message

        viewModelScope.launch(Dispatchers.IO) {
            try {
                if (sessionId.isNullOrEmpty()) {
                    sttResult.value = "Session ID not available. Restart app."
                    initializeSession()
                    return@launch
                }

                val request = ConversationMessageRequest(sessionId!!, predefinedMessage, sequenceId++)
                val response = RetrofitClient.api.sendMessage(request) // API call

                if (response.isSuccessful) {
                    val backendMessages = response.body()?.messages
                    val reply = backendMessages?.firstOrNull()?.message

                    if (!reply.isNullOrEmpty()) {
                        sttResult.value = reply
                        sendMeetingsToWatch(reply) // Send reply back to watch
                    } else {
                        sttResult.value = "No meetings found."
                        sendMeetingsToWatch("No meetings found.")
                    }
                } else {
                    sttResult.value = "Failed to fetch meetings: ${response.errorBody()?.string()}"
                }
            } catch (e: Exception) {
                sttResult.value = "Error connecting to backend: ${e.message}"
            }
        }
    }

//    private fun meetingsToday() {
//        val dummyMeetingResult = listOf(
//            "Team Sync - 12:00 AM",
//            "Project Review - 1:00 PM",
//            "Design Discussion - 2:30 PM"
//        )
//
//        // Normally, you'd fetch this data from your backend
//        // For simplicity, we'll simulate this with dummy meetings
//        val meetingsMessage = dummyMeetingResult.joinToString(", ")
//
//        // Send the data to the watch
//        sendMeetingsToWatch(meetingsMessage)
//    }

    private fun sendMeetingsToWatch(meetingsMessage: String) {
        val request = com.google.android.gms.wearable.PutDataMapRequest.create("/meetings_response").run {
            dataMap.putString("meetings_result", meetingsMessage)
            dataMap.putLong("timestamp", System.currentTimeMillis())
            asPutDataRequest().setUrgent()
        }

        Thread {
            try {
                dataClient.putDataItem(request).addOnSuccessListener {
                    android.util.Log.d("MobileApp", "Meetings sent to watch: $meetingsMessage")
                }
            } catch (e: Exception) {
                android.util.Log.e("MobileApp", "Failed to send meetings to watch", e)
            }
        }.start()
    }


    private fun sendToBackend(message: String) {
        if (sessionId.isNullOrEmpty()) {
            sttResult.value = "Session ID not available. Please restart."
            initializeSession()
            return
        }

        viewModelScope.launch(Dispatchers.IO) {
            try {
                val request = ConversationMessageRequest(sessionId!!, message, sequenceId++)
                val response = RetrofitClient.api.sendMessage(request)

                if (response.isSuccessful) {
                    val backendMessages = response.body()?.messages
                    val reply = backendMessages?.firstOrNull()?.message

                    if (!reply.isNullOrEmpty()) {
                        // Pass the reply to TTS
                        ttsText.value = reply
                        textToSpeech(reply)
                    } else {
                        sttResult.value = "No reply from the backend."
                    }
                } else {
                    sttResult.value = "Failed to send message: ${response.errorBody()?.string()}"
                }
            } catch (e: Exception) {
                sttResult.value = "Error sending message to backend: ${e.message}"
            }
        }
    }

    override fun onDataChanged(dataEvents: DataEventBuffer) {
        for (event in dataEvents) {
            when (event.dataItem.uri.path) {
                "/voice_command" -> {
                    if (event.type == DataEvent.TYPE_CHANGED) {
                        val dataMap = DataMapItem.fromDataItem(event.dataItem).dataMap
                        when (dataMap.getString("command")) {
                            "listen" -> speechToText()
                            "meeting" -> meetingsToday()
                        }
                    }
                }

                "/report_action" -> {
                    if (event.type == DataEvent.TYPE_CHANGED) {
                        val dataMap = DataMapItem.fromDataItem(event.dataItem).dataMap
                        reportAction = dataMap.getString("action") ?: "Unknown action"
                    }
                }

                "/watch/fetch_approvals" -> {
                    if (event.type == DataEvent.TYPE_CHANGED) {
                        val dataMap = DataMapItem.fromDataItem(event.dataItem).dataMap
                        val command = dataMap.getString("command")
                        if (command == "fetch_approvals") {
                            Log.d("VoiceViewModel", "Received valid approval fetch request from watch")
                            fetchApprovalsFromBackend()
                        }
                    }
                }
            }
        }
    }

    private fun fetchApprovalsFromBackend() {
        Log.d("VoiceViewModel", "fetchApprovalsFromBackend() called")

        if (sessionId.isNullOrEmpty()) {
            Log.d("VoiceViewModel", "No session ID, initializing session first")
            initializeSession()
            return
        }

        viewModelScope.launch(Dispatchers.IO) {
            try {
                Log.d("VoiceViewModel", "Sending request to backend for approvals with sessionId: $sessionId")

                val request = ConversationMessageRequest(
                    sessionId!!,
                    "List all pending approvals with their IDs and titles in numbered format",
                    sequenceId++
                )

                Log.d("VoiceViewModel", "Request prepared: $request")

                val response = RetrofitClient.api.sendMessage(request)

                Log.d("VoiceViewModel", "Received response from backend. Success: ${response.isSuccessful}")

                if (response.isSuccessful) {
                    val backendMessages = response.body()?.messages ?: emptyList()
                    Log.d("VoiceViewModel", "Received ${backendMessages.size} messages from backend")

                    if (backendMessages.isNotEmpty()) {
                        val message = backendMessages.first().message
                        Log.d("VoiceViewModel", "First message content: $message")

                        val approvals = parseApprovalsFromMessage(message)
                        Log.d("VoiceViewModel", "Parsed ${approvals.size} approvals: $approvals")

                        sendApprovalsToWatch(approvals)
                    } else {
                        Log.e("VoiceViewModel", "Empty messages from backend")
                    }
                } else {
                    Log.e("VoiceViewModel", "Backend error: ${response.errorBody()?.string()}")
                }
            } catch (e: Exception) {
                Log.e("VoiceViewModel", "Error in fetchApprovalsFromBackend", e)
            }
        }
    }
    private fun parseApprovalsFromMessage(message: String): List<String> {
        return message.split("\n")
            .filter { it.contains("- Title:") }
            .map {
                it.substringAfter("- Title:").trim()
            }
            .also {
                Log.d("VoiceViewModel", "Parsed approval titles: $it")
            }
    }

    private fun sendApprovalsToWatch(approvals: List<String>) {
        Log.d("VoiceViewModel", "Preparing to send ${approvals.size} approvals to watch")

        val approvalMap = PutDataMapRequest.create("/mobile/approvals_response").apply {
            dataMap.putStringArrayList("approvals", ArrayList(approvals))
            Log.d("VoiceViewModel", "Created data map with approvals")
        }.asPutDataRequest()

        Log.d("VoiceViewModel", "Sending data item to watch")
        Wearable.getDataClient(context).putDataItem(approvalMap).addOnCompleteListener { task ->
            if (task.isSuccessful) {
                Log.d("VoiceViewModel", "Successfully sent approvals to watch")
            } else {
                Log.e("VoiceViewModel", "Failed to send approvals to watch", task.exception)
            }
        }
    }

    private fun textToSpeech(text: String) {
        tts?.speak(text, TextToSpeech.QUEUE_FLUSH, null, null)
        isSpeaking.value = true
    }

    override fun onCleared() {
        super.onCleared()
        tts?.shutdown()
        recognizer?.destroy()
    }
}
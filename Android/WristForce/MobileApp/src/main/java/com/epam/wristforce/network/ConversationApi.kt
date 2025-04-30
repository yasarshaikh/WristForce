package com.epam.wristforce.network

import retrofit2.Response

import retrofit2.http.Body

import retrofit2.http.POST

data class StartSessionResponse(val sessionId: String)

data class ConversationMessageRequest(

    val sessionId: String,

    val message: String,

    val sequenceId: Int

)

data class ConversationMessageResponse(

    val messages: List<ConversationMessage>

)

data class ConversationMessage(

    val type: String,

    val id: String,

    val feedbackId: String?,

    val planId: String?,

    val isContentSafe: Boolean,

    val message: String, // Message to be passed to TTS

    val result: List<String>?,

    val citedReferences: List<String>?

)

data class Conversation(

    val userId : String

)

interface ConversationApi {

    @POST("api/conversation/start")

    suspend fun startConversation(@Body request: Conversation): Response<StartSessionResponse>

    @POST("api/conversation/message")

    suspend fun sendMessage(@Body request: ConversationMessageRequest): Response<ConversationMessageResponse>

}

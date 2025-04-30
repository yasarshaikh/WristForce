package com.epam.wristforce.presentation

import android.content.Context
import android.util.Log
import androidx.compose.runtime.mutableStateOf
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.google.android.gms.wearable.DataClient
import com.google.android.gms.wearable.DataEvent
import com.google.android.gms.wearable.DataEventBuffer
import com.google.android.gms.wearable.DataMapItem
import com.google.android.gms.wearable.PutDataMapRequest
import com.google.android.gms.wearable.Wearable
import kotlinx.coroutines.launch

import kotlinx.coroutines.tasks.await

class WatchViewModel(private val context: Context) : ViewModel(), DataClient.OnDataChangedListener {

    var approvals = mutableStateOf<List<String>>(emptyList())

    var isLoading = mutableStateOf(false)

    var error = mutableStateOf<String?>(null)

    init {

        Wearable.getDataClient(context).addListener(this)

        Log.d("WatchViewModel", "ViewModel initialized and listener registered")

    }

    fun requestApprovalsFromMobile() {

        isLoading.value = true

        error.value = null

        viewModelScope.launch {

            Log.d("WatchViewModel", "Attempting to request approvals from mobile...")

            try {

                val putDataRequest = PutDataMapRequest.create("/watch/fetch_approvals").apply {

                    dataMap.putString("command", "fetch_approvals")

                    dataMap.putLong("timestamp", System.currentTimeMillis())

                }.asPutDataRequest()

                val result = Wearable.getDataClient(context).putDataItem(putDataRequest).await()

                if (result != null) {

                    Log.d("WatchViewModel", "Successfully sent request to mobile. Status: ${result}")

                } else {

                    Log.e("WatchViewModel", "Failed to send request - null result")

                    error.value = "Failed to send request"

                }

            } catch (e: Exception) {

                Log.e("WatchViewModel", "Error sending request: ${e.message}", e)

                error.value = "Error: ${e.message}"

            } finally {

                isLoading.value = false

            }

        }

    }

    override fun onDataChanged(dataEvents: DataEventBuffer) {

        Log.d("WatchViewModel", "onDataChanged received ${dataEvents.count} events")

        for (event in dataEvents) {

            when (event.type) {

                DataEvent.TYPE_CHANGED -> {

                    when (event.dataItem.uri.path) {

                        "/mobile/approvals_response" -> {

                            Log.d("WatchViewModel", "Received approvals response")

                            try {

                                val dataMap = DataMapItem.fromDataItem(event.dataItem).dataMap

                                val fetchedApprovals = dataMap.getStringArrayList("approvals") ?: emptyList()

                                Log.d("WatchViewModel", "Received ${fetchedApprovals.size} approvals")

                                approvals.value = fetchedApprovals

                            } catch (e: Exception) {

                                Log.e("WatchViewModel", "Error processing approvals", e)

                                error.value = "Error processing response"

                            }

                        }

                    }

                }

                DataEvent.TYPE_DELETED -> {

                    Log.d("WatchViewModel", "Data item deleted: ${event.dataItem.uri}")

                }

            }

        }

    }

    override fun onCleared() {

        Wearable.getDataClient(context).removeListener(this)

        Log.d("WatchViewModel", "Listener removed and ViewModel cleared")

        super.onCleared()

    }

}

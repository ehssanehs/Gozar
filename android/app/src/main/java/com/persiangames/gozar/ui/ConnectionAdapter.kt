package com.persiangames.gozar.ui

import android.view.LayoutInflater
import android.view.ViewGroup
import androidx.recyclerview.widget.DiffUtil
import androidx.recyclerview.widget.ListAdapter
import androidx.recyclerview.widget.RecyclerView
import com.persiangames.gozar.data.Connection
import com.persiangames.gozar.databinding.ItemConnectionBinding

class ConnectionAdapter(
    private val onConnectionClick: (Connection) -> Unit,
    private val onDeleteClick: (Connection) -> Unit
) : ListAdapter<Connection, ConnectionAdapter.ConnectionViewHolder>(ConnectionDiffCallback()) {

    private var selectedId: Long? = null

    fun setSelectedId(id: Long?) {
        val oldSelectedId = selectedId
        selectedId = id
        
        // Notify changes for old and new selection
        currentList.forEachIndexed { index, connection ->
            if (connection.id == oldSelectedId || connection.id == selectedId) {
                notifyItemChanged(index)
            }
        }
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ConnectionViewHolder {
        val binding = ItemConnectionBinding.inflate(
            LayoutInflater.from(parent.context),
            parent,
            false
        )
        return ConnectionViewHolder(binding)
    }

    override fun onBindViewHolder(holder: ConnectionViewHolder, position: Int) {
        val connection = getItem(position)
        holder.bind(connection, connection.id == selectedId)
    }

    inner class ConnectionViewHolder(
        private val binding: ItemConnectionBinding
    ) : RecyclerView.ViewHolder(binding.root) {

        fun bind(connection: Connection, isSelected: Boolean) {
            binding.textName.text = connection.name
            binding.textProtocol.text = connection.protocol.uppercase()
            binding.textServer.text = "${connection.serverHost}:${connection.serverPort}"
            
            // Highlight selected connection
            binding.root.alpha = if (isSelected) 1.0f else 0.7f
            binding.iconSelected.visibility = if (isSelected) {
                android.view.View.VISIBLE
            } else {
                android.view.View.GONE
            }
            
            binding.root.setOnClickListener {
                onConnectionClick(connection)
            }
            
            binding.buttonDelete.setOnClickListener {
                onDeleteClick(connection)
            }
        }
    }

    private class ConnectionDiffCallback : DiffUtil.ItemCallback<Connection>() {
        override fun areItemsTheSame(oldItem: Connection, newItem: Connection): Boolean {
            return oldItem.id == newItem.id
        }

        override fun areContentsTheSame(oldItem: Connection, newItem: Connection): Boolean {
            return oldItem == newItem
        }
    }
}

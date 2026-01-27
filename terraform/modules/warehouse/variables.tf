variable "warehouse_name" {
  description = "Name of the Snowflake warehouse"
  type        = string
}

variable "warehouse_comment" {
  description = "Comment for the warehouse"
  type        = string
  default     = ""
}

variable "warehouse_size" {
  description = "Size of the warehouse (X-Small, Small, Medium, Large, X-Large, 2X-Large, 3X-Large, 4X-Large)"
  type        = string
  default     = "X-Small"
}

variable "auto_suspend" {
  description = "Number of seconds of inactivity after which the warehouse is automatically suspended"
  type        = number
  default     = 60
}

variable "auto_resume" {
  description = "Specifies whether to automatically resume the warehouse when a query is submitted"
  type        = bool
  default     = true
}

variable "initially_suspended" {
  description = "Specifies whether the warehouse is created initially in suspended state"
  type        = bool
  default     = true
}

variable "min_cluster_count" {
  description = "Minimum number of clusters for multi-cluster warehouse"
  type        = number
  default     = 1
}

variable "max_cluster_count" {
  description = "Maximum number of clusters for multi-cluster warehouse"
  type        = number
  default     = 1
}

variable "scaling_policy" {
  description = "Scaling policy for multi-cluster warehouse (STANDARD or ECONOMY)"
  type        = string
  default     = "STANDARD"
}

variable "statement_timeout_in_seconds" {
  description = "Timeout in seconds for statements executed by the warehouse"
  type        = number
  default     = 172800 # 48 hours
}

variable "statement_queued_timeout_in_seconds" {
  description = "Timeout in seconds for statements queued for the warehouse"
  type        = number
  default     = 0 # No timeout
}

variable "resource_monitor" {
  description = "Name of the resource monitor to associate with the warehouse"
  type        = string
  default     = null
}

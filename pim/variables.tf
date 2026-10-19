variable "subscription_id" {
  description = "The Azure subscription to protect"
  type        = string
}

variable "requester_object_id" {
  description = "The person who can ask for Owner (Rog)"
  type        = string
}

variable "approver_object_id" {
  description = "The person who must approve the request (lab-it.admin)"
  type        = string
}
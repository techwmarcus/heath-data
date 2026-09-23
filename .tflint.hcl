config {
  module = true
  force  = false
}

# Example: Remove or change this if you use Azure or GCP instead of AWS
plugin "aws" {
  enabled = true
  version = "0.31.0"
  source  = "://github.com"
}

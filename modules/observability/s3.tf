# Random suffix for bucket names to ensure uniqueness
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# Loki Logs Bucket
resource "aws_s3_bucket" "loki_logs" {
  bucket = "${var.cluster_name}-loki-logs-${random_id.bucket_suffix.hex}"
  
  tags = var.tags
}

# Tempo Traces Bucket
resource "aws_s3_bucket" "tempo_traces" {
  bucket = "${var.cluster_name}-tempo-traces-${random_id.bucket_suffix.hex}"
  
  tags = var.tags
}

# Block public access for Loki bucket
resource "aws_s3_bucket_public_access_block" "loki_logs" {
  bucket = aws_s3_bucket.loki_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Block public access for Tempo bucket
resource "aws_s3_bucket_public_access_block" "tempo_traces" {
  bucket = aws_s3_bucket.tempo_traces.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

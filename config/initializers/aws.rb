Aws.config.update(
  region: ENV['AWS_REGION'],
  credentials: Aws::Credentials.new(ENV['S3_ACCESS_KEY_ID'], ENV['S3_SECRET_ACCESS_KEY'])
)

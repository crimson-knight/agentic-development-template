require "gemma"
require "gemma/grant"
require "awscr-s3"

# Configure Gemma file attachment system
Gemma.configure do |config|
  # Development and Test: Use filesystem storage
  if Amber.env.development? || Amber.env.test?
    # Cache storage for temporary uploads
    config.storages["cache"] = Gemma::Storage::FileSystem.new(
      "public/uploads/cache",
      prefix: "cache"
    )

    # Permanent storage
    config.storages["store"] = Gemma::Storage::FileSystem.new(
      "public/uploads"
    )
  end

  # Production: Use S3-compatible storage
  if Amber.env.production?

    # Initialize S3 client
    client = Awscr::S3::Client.new(
      ENV["S3_REGION"],
      ENV["S3_KEY"],
      ENV["S3_SECRET"],
      endpoint: ENV["S3_ENDPOINT"]?
    )

    # Cache storage (temporary, not public)
    config.storages["cache"] = Gemma::Storage::S3.new(
      bucket: ENV["S3_BUCKET"],
      client: client,
      prefix: "cache",
      public: false
    )

    # Permanent storage (public access)
    config.storages["store"] = Gemma::Storage::S3.new(
      bucket: ENV["S3_BUCKET"],
      client: client,
      prefix: "uploads",
      public: true,
      upload_options: {
        "x-amz-acl" => "public-read",
      }
    )
  end
end

# Load Gemma plugins
# Note: Plugin API may vary by Gemma version
# Uncomment and adjust based on your Gemma version's plugin system
#
# class ApplicationUploader < Gemma
#   # Determine MIME type from file contents
#   load_plugin(
#     Gemma::Plugins::DetermineMimeType,
#     analyzer: Gemma::Plugins::DetermineMimeType::Tools::File
#   )
#
#   # Store image dimensions (requires fastimage shard)
#   # load_plugin(
#   #   Gemma::Plugins::StoreDimensions,
#   #   analyzer: Gemma::Plugins::StoreDimensions::Tools::FastImage
#   # )
#
#   finalize_plugins!
# end

# Gemma Grant Integration features:
# - has_one_attached :field_name - Single file attachment
# - has_many_attached :field_name - Multiple file attachments
# - validate_file_size_of :field_name, maximum: 5.megabytes
# - validate_content_type_of :field_name, accept: ["image/jpeg", "image/png"]
#
# Usage in models:
#   include Gemma::Grant::Attachable
#   include Gemma::Grant::AttachmentValidators
#   column avatar_data : JSON::Any?
#   has_one_attached :avatar

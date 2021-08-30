# frozen_string_literal: true

class CommentBlueprint < Blueprinter::Base
  identifier :id

  fields :text, :commentable_id, :commentable_type, :comment_type, :reference_type, :reference_id
  field :created_at do |comment, options|
    comment.created_at.in_time_zone(options[:current_user] ? options[:current_user].time_zone : Time.zone).strftime(Blueprinter::DATETIME_FORMAT)
  end

  association :user, blueprint: UserBlueprint, view: :avatar
  association :reference, blueprint: ->(reference) { "#{reference.model_name}Blueprint".constantize }, default: {}

  # appending "_attachments" to the field name is the default convention for ActiveStorage
  association :attachments_attachments, blueprint: AttachmentBlueprint

  view :studio do
    field :help_text_creative do |comment, options|
      comment.help_text(:creative) if comment.comment_type == "help"
    end
    field :help_text_client do |comment, options|
      comment.help_text(:client) if comment.comment_type == "help"
    end
    field :help_text_other do |comment, options|
      comment.help_text(:other) if comment.comment_type == "help"
    end
  end
end

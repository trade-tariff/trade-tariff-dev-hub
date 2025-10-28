class NotificationSerializer
  include FastJsonapi::ObjectSerializer

  set_type :notification

  attributes :email,
             :template_id,
             :email_reply_to_id,
             :personalisation,
             :reference
end

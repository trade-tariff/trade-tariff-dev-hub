NOTIFY_CONFIGURATION = if ENV['ENVIRONMENT'] == 'production'
  {
    templates: {
      developer_portal: {
        invitation: 'ec674766-30ab-40a1-87e6-c7b43e80ae9b',
        role_request_approved: 'fa6a7e13-af85-4166-9899-48fa865f3c19',
        role_request_created: 'be46e49d-6291-4bfc-a79d-f4fbe5a63641',
        role_request_rejected: '793509cd-49ab-47a5-ab6e-ad44bcced970',
      },
    }
  }
elsif ENV['ENVIRONMENT'] == 'staging'
  {
    templates: {
      developer_portal: {
        invitation: 'dbdc7cf1-c44b-4f24-9654-bedcfae56f6f',
        role_request_approved: '73336beb-71aa-4b40-8c41-f0315584f0c2',
        role_request_created: '3d2cef6c-0879-4d8b-b174-1f5fdf7a87d8',
        role_request_rejected: 'fd3ff633-e52e-4205-99d5-8a0e3894d3a8',
      },
    },
  }
else # development / default
  {
    templates: {
      developer_portal: {
        invitation: 'c74b7b8b-eb6c-4a33-b1c0-61b3dcb54aeb',
        role_request_approved: 'aefe2597-ff21-4642-b4bf-0b0292797859',
        role_request_created: '41d98840-34b0-43f3-a059-cbd3ceff17be',
        role_request_rejected: 'a70bf451-63da-4459-861a-155cae7707fb',
      },
    },
  }
end

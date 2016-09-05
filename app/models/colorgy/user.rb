module Colorgy
  class User < ColorgyRecord
    self.table_name = 'users'

    belongs_to :organization, primary_key: :code, foreign_key: :organization_code

    has_many :school_system_data, class_name: '::Colorgy::UserSchoolSystemDatum'
    has_many :attendance_ships,   class_name: '::Colorgy::AttendanceShip'
    has_many :enroll_courses,     class_name: '::Colorgy::Course', through: :attendance_ships, source: :course
  end
end

# == Schema Information
#
# Table name: users
#
#  id                          :integer          not null, primary key
#  email                       :string           default("")
#  encrypted_password          :string           default(""), not null
#  reset_password_token        :string
#  reset_password_sent_at      :datetime
#  remember_created_at         :datetime
#  sign_in_count               :integer          default(0), not null
#  current_sign_in_at          :datetime
#  last_sign_in_at             :datetime
#  current_sign_in_ip          :inet
#  last_sign_in_ip             :inet
#  confirmation_token          :string
#  confirmed_at                :datetime
#  confirmation_sent_at        :datetime
#  unconfirmed_email           :string
#  failed_attempts             :integer          default(0), not null
#  unlock_token                :string
#  locked_at                   :datetime
#  name                        :string           default(""), not null
#  username                    :string
#  external_avatar_url         :string
#  external_cover_photo_url    :string
#  uuid                        :uuid             not null
#  fbid                        :string
#  fbtoken                     :string
#  fbemail                     :string
#  fb_devices                  :text
#  fb_friends                  :text
#  gender                      :integer          default("unspecified"), not null
#  birth_year                  :integer
#  birth_month                 :integer
#  birth_day                   :integer
#  url                         :string           default(""), not null
#  brief                       :text             default(""), not null
#  motto                       :text             default(""), not null
#  avatar_file_name            :string
#  avatar_content_type         :string
#  avatar_file_size            :integer
#  avatar_updated_at           :datetime
#  cover_photo_file_name       :string
#  cover_photo_content_type    :string
#  cover_photo_file_size       :integer
#  cover_photo_updated_at      :datetime
#  organization_code           :string
#  test_account_type           :integer
#  mobile                      :string
#  unconfirmed_mobile          :string
#  mobile_confirmation_token   :string
#  mobile_confirmation_sent_at :datetime
#  mobile_confirm_tries        :integer          default(0), not null
#  started_year                :string
#  avatar_crop_x               :integer
#  avatar_crop_y               :integer
#  avatar_crop_w               :integer
#  avatar_crop_h               :integer
#  avatar_local                :boolean          default(FALSE), not null
#  cover_photo_local           :boolean          default(FALSE), not null
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#  mobile_confirmed_at         :datetime
#  settings                    :hstore
#  followers_count             :integer          default(0)
#  otp_secret_key              :string
#  otp_sms_sent_at             :datetime
#  otp_failed_attempts         :integer          default(0), not null
#  pokes_count                 :integer          default(0)
#  global_updated_at           :datetime
#  department_id               :integer
#
# Indexes
#
#  index_users_on_confirmation_token    (confirmation_token) UNIQUE
#  index_users_on_department_id         (department_id)
#  index_users_on_fbemail               (fbemail)
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#  index_users_on_unlock_token          (unlock_token) UNIQUE
#  index_users_on_uuid                  (uuid) UNIQUE
#

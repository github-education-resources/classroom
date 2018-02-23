# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20180223161920) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "assignment_invitations", id: :serial, force: :cascade do |t|
    t.string "key", null: false
    t.integer "assignment_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.string "short_key"
    t.index ["assignment_id"], name: "index_assignment_invitations_on_assignment_id"
    t.index ["deleted_at"], name: "index_assignment_invitations_on_deleted_at"
    t.index ["key"], name: "index_assignment_invitations_on_key", unique: true
    t.index ["short_key"], name: "index_assignment_invitations_on_short_key"
  end

  create_table "assignment_repos", id: :serial, force: :cascade do |t|
    t.integer "github_repo_id", null: false
    t.integer "repo_access_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "assignment_id"
    t.integer "user_id"
    t.string "submission_sha"
    t.string "global_relay_id"
    t.integer "configuration_state", default: 0
    t.index ["assignment_id"], name: "index_assignment_repos_on_assignment_id"
    t.index ["github_repo_id"], name: "index_assignment_repos_on_github_repo_id", unique: true
    t.index ["global_relay_id"], name: "index_assignment_repos_on_global_relay_id"
    t.index ["repo_access_id"], name: "index_assignment_repos_on_repo_access_id"
    t.index ["user_id"], name: "index_assignment_repos_on_user_id"
  end

  create_table "assignments", id: :serial, force: :cascade do |t|
    t.boolean "public_repo", default: true
    t.string "title", null: false
    t.integer "organization_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "starter_code_repo_id"
    t.integer "creator_id"
    t.datetime "deleted_at"
    t.string "slug", null: false
    t.boolean "students_are_repo_admins", default: false, null: false
    t.boolean "invitations_enabled", default: true
    t.index ["deleted_at"], name: "index_assignments_on_deleted_at"
    t.index ["organization_id"], name: "index_assignments_on_organization_id"
    t.index ["slug"], name: "index_assignments_on_slug"
  end

  create_table "deadlines", id: :serial, force: :cascade do |t|
    t.string "assignment_type"
    t.integer "assignment_id"
    t.datetime "deadline_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assignment_type", "assignment_id"], name: "index_deadlines_on_assignment_type_and_assignment_id"
  end

  create_table "group_assignment_invitations", id: :serial, force: :cascade do |t|
    t.string "key", null: false
    t.integer "group_assignment_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.string "short_key"
    t.index ["deleted_at"], name: "index_group_assignment_invitations_on_deleted_at"
    t.index ["group_assignment_id"], name: "index_group_assignment_invitations_on_group_assignment_id"
    t.index ["key"], name: "index_group_assignment_invitations_on_key", unique: true
    t.index ["short_key"], name: "index_group_assignment_invitations_on_short_key"
  end

  create_table "group_assignment_repos", id: :serial, force: :cascade do |t|
    t.integer "github_repo_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "group_assignment_id"
    t.integer "group_id", null: false
    t.string "submission_sha"
    t.integer "configuration_state", default: 0
    t.index ["github_repo_id"], name: "index_group_assignment_repos_on_github_repo_id", unique: true
    t.index ["group_assignment_id"], name: "index_group_assignment_repos_on_group_assignment_id"
  end

  create_table "group_assignments", id: :serial, force: :cascade do |t|
    t.boolean "public_repo", default: true
    t.string "title", null: false
    t.integer "grouping_id"
    t.integer "organization_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "starter_code_repo_id"
    t.integer "creator_id"
    t.datetime "deleted_at"
    t.string "slug", null: false
    t.integer "max_members"
    t.boolean "students_are_repo_admins", default: false, null: false
    t.boolean "invitations_enabled", default: true
    t.index ["deleted_at"], name: "index_group_assignments_on_deleted_at"
    t.index ["organization_id"], name: "index_group_assignments_on_organization_id"
    t.index ["slug"], name: "index_group_assignments_on_slug"
  end

  create_table "groupings", id: :serial, force: :cascade do |t|
    t.string "title", null: false
    t.integer "organization_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "slug", null: false
    t.index ["organization_id"], name: "index_groupings_on_organization_id"
  end

  create_table "groups", id: :serial, force: :cascade do |t|
    t.integer "github_team_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "grouping_id"
    t.string "title", null: false
    t.string "slug", null: false
    t.index ["github_team_id"], name: "index_groups_on_github_team_id", unique: true
    t.index ["grouping_id"], name: "index_groups_on_grouping_id"
  end

  create_table "groups_repo_accesses", id: false, force: :cascade do |t|
    t.integer "group_id"
    t.integer "repo_access_id"
    t.index ["group_id"], name: "index_groups_repo_accesses_on_group_id"
    t.index ["repo_access_id"], name: "index_groups_repo_accesses_on_repo_access_id"
  end

  create_table "organizations", id: :serial, force: :cascade do |t|
    t.integer "github_id", null: false
    t.string "title", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.string "slug", null: false
    t.integer "webhook_id"
    t.boolean "is_webhook_active", default: false
    t.integer "roster_id"
    t.index ["deleted_at"], name: "index_organizations_on_deleted_at"
    t.index ["github_id"], name: "index_organizations_on_github_id"
    t.index ["roster_id"], name: "index_organizations_on_roster_id"
    t.index ["slug"], name: "index_organizations_on_slug"
  end

  create_table "organizations_users", id: false, force: :cascade do |t|
    t.integer "user_id"
    t.integer "organization_id"
    t.index ["organization_id"], name: "index_organizations_users_on_organization_id"
    t.index ["user_id"], name: "index_organizations_users_on_user_id"
  end

  create_table "repo_accesses", id: :serial, force: :cascade do |t|
    t.integer "github_team_id"
    t.integer "organization_id"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["github_team_id"], name: "index_repo_accesses_on_github_team_id", unique: true
    t.index ["organization_id"], name: "index_repo_accesses_on_organization_id"
    t.index ["user_id"], name: "index_repo_accesses_on_user_id"
  end

  create_table "roster_entries", force: :cascade do |t|
    t.string "identifier", null: false
    t.bigint "roster_id", null: false
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["roster_id"], name: "index_roster_entries_on_roster_id"
    t.index ["user_id"], name: "index_roster_entries_on_user_id"
  end

  create_table "rosters", force: :cascade do |t|
    t.string "identifier_name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.integer "uid", null: false
    t.string "token", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "site_admin", default: false
    t.datetime "last_active_at", null: false
    t.index ["token"], name: "index_users_on_token", unique: true
    t.index ["uid"], name: "index_users_on_uid", unique: true
  end

end

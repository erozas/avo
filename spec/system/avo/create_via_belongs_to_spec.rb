# frozen_string_literal: true

require "rails_helper"

RSpec.describe 'Create Via Belongs to', type: :system do
  describe 'edit' do
    let(:course_link) { create(:course_link) }

    context 'with non-searchable belongs_to' do
      let(:fish) { create(:fish, user: create(:user)) }

      it 'successfully creates a new user and assigns it to the comment', :aggregate_failures do
        visit "/admin/resources/fish/#{fish.id}/edit"

        click_on 'Create new user'

        expect do
          within('.modal-container') do
            fill_in 'user_email', with: "#{SecureRandom.hex(12)}@gmail.com"
            fill_in 'user_first_name', with: 'FirstName'
            fill_in 'user_last_name', with: 'LastName'
            fill_in 'user_password', with: 'password'
            fill_in 'user_password_confirmation', with: 'password'
            click_on "Save"
            sleep 0.2
          end
        end.to change(User, :count).by(1)

        expect(page).to have_select('fish_user_id', selected: User.last.name)

        click_on "Save"
        sleep 0.2

        expect(fish.reload.user).to eq User.last
      end
    end

    context 'with polymorphic belongs_to' do
      let(:comment) { create(:comment, user: create(:user), commentable: create(:project)) }

      it 'successfully creates a new commentable and assigns it to the comment', :aggregate_failures do
        visit "/admin/resources/comments/#{comment.to_param}/edit"

        page.select 'Post', from: 'comment_commentable_type'
        click_on 'Create new post'

        expect do
          within('.modal-container') do
            fill_in 'post_name', with: 'Test post'
            click_on "Save"
            sleep 0.2
          end
        end.to change(Post, :count).by(1)

        expect(page).to have_select('comment_commentable_id', selected: Post.last.name)

        click_on "Save"
        sleep 0.2

        expect(comment.reload.commentable).to eq Post.last
      end
    end
  end

  context 'with non-searchable belongs_to' do
    it 'successfully creates a new user and assigns it to the comment', :aggregate_failures do
      visit '/admin/resources/fish/new'

      click_on 'Create new user'

      expect do
        within('.modal-container') do
          fill_in 'user_email', with: "#{SecureRandom.hex(12)}@gmail.com"
          fill_in 'user_first_name', with: 'FirstName'
          fill_in 'user_last_name', with: 'LastName'
          fill_in 'user_password', with: 'password'
          fill_in 'user_password_confirmation', with: 'password'
          click_on "Save"
          sleep 0.2
        end
      end.to change(User, :count).by(1)
      expect(User.last).to have_attributes(
        first_name: 'FirstName',
        last_name: 'LastName'
      )
      expect(page).to have_select('fish_user_id', selected: User.last.name)

      expect do
        click_on "Save"
        sleep 0.2
      end.to change(Fish, :count).by(1)

      expect(Fish.last.user).to eq User.last
    end

    context "when belongs_to record options exceeds associations_lookup_list_limit" do
      let!(:course) { create :course }
      let!(:exceeded_course) { create :course }

      before { Avo.configuration.associations_lookup_list_limit = 1 }
      after { Avo.configuration.associations_lookup_list_limit = 1000 }

      it "limits select options" do
        visit "/admin/resources/course_links/new"
        expect(page).to have_select "course_link_course_id", options: ["Choose an option", course.name, "There are more records available."]
        expect(page).to have_selector 'option[disabled="disabled"][value="There are more records available."]'
      end
    end
  end

  context 'with polymorphic belongs_to' do
    it 'successfully creates a new commentable and assigns it to the comment', :aggregate_failures do
      visit "/admin/resources/comments/new"

      fill_in 'comment_body', with: 'Test comment'

      page.select 'Post', from: 'comment_commentable_type'
      click_on 'Create new post'

      expect do
        within('.modal-container') do
          fill_in 'post_name', with: 'Test post'
          click_on "Save"
          sleep 0.2
        end
      end.to change(Post, :count).by(1)

      expect(page).to have_select('comment_commentable_id', selected: Post.last.name)

      expect do
        fill_in 'comment_body', with: 'Test Comment'
        click_on "Save"
        sleep 0.2
      end.to change(Comment, :count).by(1)

      expect(Comment.last).to have_attributes(
        body: 'Test Comment',
        commentable: Post.last
      )
    end

    context "when belongs_to record options exceeds associations_lookup_list_limit" do
      let!(:user) { User.first }
      let!(:exceeded_user) { create :user }

      before { Avo.configuration.associations_lookup_list_limit = 1 }
      after { Avo.configuration.associations_lookup_list_limit = 1000 }

      it "limits select options" do
        visit "/admin/resources/comments/new"
        expect(page).to have_select "comment_user_id", options: ["Choose an option", user.name, "There are more records available."]
        expect(page).to have_selector 'option[disabled="disabled"][value="There are more records available."]'
      end
    end
  end

  context 'with models that uses prefix_id' do
    it 'successfully creates a new course and assigns it to the course link', :aggregate_failures do
      visit '/admin/resources/course_links/new'

      fill_in 'course_link_link', with: 'Test link'

      click_on 'Create new course'

      expect do
        within('.modal-container') do
          fill_in 'course_name', with: 'Test course'
          click_on "Save"
          sleep 0.2
        end
      end.to change(Course, :count).by(1)

      expect(page).to have_select('course_link_course_id', selected: Course.last.name)

      expect do
        click_on "Save"
        sleep 0.2
      end.to change(Course::Link, :count).by(1)

      expect(Course::Link.last).to have_attributes(
        link: 'Test link',
        course: Course.last
      )
    end
  end

  context 'disable' do
    it 'dont show the link', :aggregate_failures do
      Avo::Resources::CourseLink.with_temporary_items do
        field :course, as: :belongs_to, searchable: true, can_create: false
      end

      visit '/admin/resources/course_links/new'

      within field_wrapper(:course) do
        expect(page).not_to have_text 'Create new course'
      end

      Avo::Resources::CourseLink.restore_items_from_backup
    end
  end
end

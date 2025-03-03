require 'helper'
require 'pry'

describe Octokit::Client::Projects do

  describe ".repo_projects", :vcr do
    it "returns a list of projects for a repository" do
      projects = oauth_client.repo_projects('octokit/octokit.rb', accept: preview_header)
      expect(projects).to be_kind_of Array
      assert_requested :get, github_url("/repos/octokit/octokit.rb/projects")
    end
  end # .repo_projects

  describe ".create_repo_project", :vcr do
    it "returns the newly created project" do
      project = oauth_client.create_repo_project(@test_repo, "api kpi", accept: preview_header)
      expect(project.name).to eq("api kpi")
      assert_requested :post, github_url("/repos/#{@test_repo}/projects")
    end
  end # .create_repo_project

  describe ".org_projects", :vcr do
    it "returns the projects for an organization" do
      projects = oauth_client.org_projects(test_github_org, accept: preview_header)
      expect(projects).to be_kind_of Array
      assert_requested :get, github_url("/orgs/#{test_github_org}/projects")
    end
  end # .org_project

  describe ".create_org_project", :vcr do
    it "returns the new org project" do
      project = oauth_client.create_org_project(test_github_org, "synergy", body: "do it", accept: preview_header)
      expect(project.name).to eq "synergy"
      expect(project.body).to eq "do it"
      assert_requested :post, github_url("/orgs/#{test_github_org}/projects")
      oauth_client.delete_project(project.id, accept: preview_header)
    end
  end # .create_org_project

  context "with org project" do
    before(:each) do
      project = oauth_client.create_org_project(test_github_org, "org test project", accept: preview_header)
      @project_id = project.id
      @user = "hmharvey"
    end

    after(:each) do
      project = oauth_client.delete_project(@project_id, accept: preview_header)
    end

    describe ".project_collaborators", :vcr do
      it "returns a list of projects collaborators" do
        collaborators = oauth_client.project_collaborators(@project_id, accept: preview_header)
        expect(collaborators).to be_kind_of Array
        assert_requested :get, github_url("/projects/#{@project_id}/collaborators")
      end
    end # .project_collaborators

    describe ".add_project_collaborator", :vcr do
      it "adds a project collaborator" do
        result = oauth_client.add_project_collaborator(@project_id, @user, accept: preview_header)
        expect(result).to eq true
        assert_requested :put, github_url("/projects/#{@project_id}/collaborators/#{@user}")
      end
    end # .add_project_collaborator

    context "with collaborator" do
      before(:each) do
        result = oauth_client.add_project_collaborator(@project_id, @user, accept: preview_header)
      end

      describe ".remove_project_collaborator", :vcr do
        it "removes a project collaborator" do
          result = oauth_client.remove_project_collaborator(@project_id, @user, accept: preview_header)
          expect(result).to eq true
          assert_requested :put, github_url("/projects/#{@project_id}/collaborators/#{@user}")
        end
      end # .remove_project_collaborator

      describe ".user_permission", :vcr do
        it "returns a user's permission level" do
          result = oauth_client.user_permission(@project_id, @user, accept: preview_header)
          expect(result.permission).to be_kind_of String
          assert_requested :get, github_url("/projects/#{@project_id}/collaborators/#{@user}/permission")
        end
      end # .user_permission
    end # with collaborator
  end # with org project

  context "with repository" do
    context "with project" do
      before(:each) do
        @project = oauth_client.create_repo_project(@test_repo, "implement apis", accept: preview_header)
      end

      after(:each) do
        oauth_client.delete_project(@project.id, accept: preview_header)
      end

      describe ".project", :vcr do
        it "returns a project" do
          project = oauth_client.project(@project.id, accept: preview_header)
          expect(project.name).not_to be_nil
          assert_requested :get, github_url("/projects/#{@project.id}")
        end
      end # .project

      describe ".update_project", :vcr do
        it "updates the project name and body then returns the updated project" do
          name = "new name"
          body = "new body"
          project = oauth_client.update_project(@project.id, {name: name, body: body, accept: preview_header})
          expect(project.name).to eq name
          expect(project.body).to eq body
          assert_requested :patch, github_url("/projects/#{@project.id}")
        end

        it "helper methods close and reopen the project" do
          project = oauth_client.close_project(@project.id, accept: preview_header)
          expect(project.state).to eq "closed"
          project = oauth_client.reopen_project(@project.id, accept: preview_header)
          expect(project.state).to eq "open"
          assert_requested :patch, github_url("/projects/#{@project.id}"), :times => 2
        end
      end # .update_project

      describe ".delete_project", :vcr do
        it "returns the result of deleting a project" do
          oauth_client.delete_project(@project.id, accept: preview_header)
          assert_requested :delete, github_url("/projects/#{@project.id}")
        end
      end # .delete_project

      describe ".project_columns", :vcr do
        it "returns the columns for a project" do
          columns = oauth_client.project_columns(@project.id, accept: preview_header)
          expect(columns).to be_kind_of Array
          assert_requested :get, github_url("/projects/#{@project.id}/columns")
        end
      end # .project_columns

      describe ".create_project_column", :vcr do
        it "returns the newly created project column" do
          column = oauth_client.create_project_column(@project.id, "Todos", accept: preview_header)
          expect(column.name).to eq "Todos"
          assert_requested :post, github_url("/projects/#{@project.id}/columns")
        end
      end # .create_project_column

      context "with project column" do
        before(:each) do
          @column = oauth_client.create_project_column(@project.id, "Todos #{Time.now.to_f}", accept: preview_header)
        end

        after(:each) do
          oauth_client.delete_project_column(@column.id, accept: preview_header)
        end

        describe ".project_column", :vcr do
          it "returns a project column by id" do
            column = oauth_client.project_column(@column.id, accept: preview_header)
            expect(column.name).to be_kind_of String
            assert_requested :get, github_url("/projects/columns/#{@column.id}")
          end
        end # .project_column

        describe ".update_project_column", :vcr do
          it "updates the project column and returns the updated column" do
            column = oauth_client.update_project_column(@column.id, "new name", accept: preview_header)
            expect(column.name).to eq "new name"
            assert_requested :patch, github_url("/projects/columns/#{@column.id}")
          end
        end # .update_project_column

        describe ".move_project_column", :vcr do
          it "moves the project column" do
            result = oauth_client.move_project_column(@column.id, "last", accept: preview_header)
            assert_requested :post, github_url("/projects/columns/#{@column.id}/moves")
            expect(result).to eq(true)
          end
        end # .move_project_column

        describe ".delete_project_column", :vcr do
          it "deletes the project column" do
            result = oauth_client.delete_project_column(@column.id, accept: preview_header)
            expect(result).to eq true
            assert_requested :delete, github_url("/projects/columns/#{@column.id}")
          end
        end # .delete_project_column

        describe ".project_cards", :vcr do
          it "returns a list of the cards in a project column" do
            cards = oauth_client.project_cards(@column.id, accept: preview_header)
            expect(cards).to be_kind_of Array
            assert_requested :get, github_url("/projects/columns/#{@column.id}/cards")
          end
        end # .project_cards

        describe ".create_project_card", :vcr do
          it "creates a new card with a note" do
            card = oauth_client.create_project_card(@column.id, note: 'thing', accept: preview_header)
            expect(card.note).to eq 'thing'
            assert_requested :post, github_url("/projects/columns/#{@column.id}/cards")
          end
        end # .create_project_card

        context "with project card" do
          before(:each) do
            @card = oauth_client.create_project_card(@column.id, note: 'octocard', accept: preview_header)
          end

          after(:each) do
            oauth_client.delete_project_card(@card.id, accept: preview_header)
          end

          describe ".project_card", :vcr do
            it "returns a project card by id" do
              card = oauth_client.project_card(@card.id, accept: preview_header)
              expect(card.note).to be_kind_of String
              assert_requested :get, github_url("/projects/columns/cards/#{@card.id}")
            end
          end # .project_card

          describe ".update_project_card", :vcr do
            it "updates the project card" do
              card = oauth_client.update_project_card(@card.id, note: 'new note', accept: preview_header)
              expect(card.note).to eq 'new note'
              assert_requested :patch, github_url("/projects/columns/cards/#{@card.id}")
            end
          end # .update_project_card

          describe ".move_project_card", :vcr do
            it "moves the project card" do
              result = oauth_client.move_project_card(@card.id, 'bottom', accept: preview_header)
              assert_requested :post, github_url("/projects/columns/cards/#{@card.id}/moves")
              expect(result).to eq(true)
            end
          end # .move_project_card

          describe ".delete_project_card", :vcr do
            it "deletes the project card" do
              success = oauth_client.delete_project_card(@card.id, accept: preview_header)
              expect(success).to eq true
              assert_requested :delete, github_url("/projects/columns/cards/#{@card.id}")
            end
          end # .delete_project_card
        end # with project card
      end # with project column
    end # with project
  end # with repository

  private

  def preview_header
    Octokit::Preview::PREVIEW_TYPES[:projects]
  end
end # Octokit::Client::Projects

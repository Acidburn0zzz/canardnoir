class StacksController < ApplicationController
  helper RatingsHelper

  before_action :session_required, except: [:index, :show, :similar]
  before_action :find_stack, except: [:index, :create]
  before_action :can_edit_stack, except: [:index, :show, :create, :similar]
  before_action :find_account, only: [:index, :show]
  before_action :auto_ignore, only: [:builder]

  def index
    @stacks = @account.stacks
  end

  def create
    @stack = Stack.new
    @stack.account = current_user
    if @stack.save
      redirect_to stack_path(@stack)
    else
      redirect_to account_stacks_path(current_user), notice: t('.error')
    end
  end

  def update
    render nothing: true, status: (@stack.update_attributes(model_params) ? :ok : :unprocessable_entity)
  end

  def destroy
    render nothing: true, status: (@stack.destroy ? :ok : :unprocessable_entity)
  end

  def similar
    @similar_stacks = @stack.similar_stacks
  end

  def builder
    @recommendations = render_to_string(partial: 'small_suggestion.html.haml', collection: @stack.suggest_projects(5))
    render json: { recommendations: @recommendations }
  end

  private

  def model_params
    params.require(:stack).permit([:title, :description])
  end

  def find_stack
    @stack = Stack.find_by_id(params[:id])
    fail ParamRecordNotFound if @stack.nil?
  end

  def can_edit_stack
    fail ParamRecordNotFound if (@stack.account_id != current_user.id)
  end

  def find_account
    @account = params[:account_id] ? Account.resolve_login(params[:account_id]) : @stack.account
    fail ParamRecordNotFound unless @account && Account::Access.new(@account).active_and_not_disabled?
  end

  def auto_ignore
    (params[:ignore] || []).split(',').compact.each do |project_url_name|
      proj = Project.find_by_url_name(project_url_name)
      StackIgnore.create(stack_id: @stack.id, project_id: proj.id) if proj
    end
  end
end
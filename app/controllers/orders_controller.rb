class OrdersController < ApplicationController
  def index
    @orders = Order.where(user_id: current_user.id).order(created_at: :desc)
  end

  def new
    @order = Order.new
    @order.ordered_lists.build
    @items = Item.all.order(:created_at)
  end

  def create
    ActiveRecord::Base.transaction do
      @order = current_user.orders.build(order_params)
      begin
        @order.ordered_lists.each do |ordered_list|
          next if ordered_list.quantity == 0  # 注文数が0のアイテムはスキップ
          item = Item.lock.find(ordered_list.item_id)
          # 商品の注文数を加算する
          item.add_ordered_quantity!(ordered_list.quantity)
        end

        if @order.save
          redirect_to orders_path, notice: "注文が完了しました"
        else
          flash[:alert] = "注文の保存に失敗しました"
          @items = Item.all.order(:created_at)  # @itemsを再取得
          render :new
        end

      rescue StandardError => e
        flash[:alert] = e.message
        @items = Item.all.order(:created_at)  # @itemsを再取得
        render :new  # ページを再描画してエラーメッセージを表示
      end
    end
  end

  private

  def order_params
    params.require(:order).permit(ordered_lists_attributes: [:item_id, :quantity])
  end

end

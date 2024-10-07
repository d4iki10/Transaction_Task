class Item < ApplicationRecord
  validates :name, presence: true
  validates :total_quantity, presence: true
  has_many :orders, through: :ordered_lists

  # 在庫を減らすメソッド
  def reduce_stock!(quantity)
    return if quantity <= 0

    self.class.transaction do
      item = Item.lock.find(self.id)  # 悲観的ロックを適用してアイテムをロック
      if item.total_quantity >= quantity
        item.total_quantity += quantity
        item.save!
      else
        raise StandardError, "#{item.name}の在庫が足りません（残り#{item.total_quantity}個）"
      end
    end
  end

  # 注文数を加算するメソッド
  def add_ordered_quantity!(quantity)
    self.class.transaction do
      item = Item.lock.find(self.id)  # 悲観的ロックを適用
      item.total_quantity += quantity  # total_quantityに注文数を加算
      item.save!
    end
  end
end

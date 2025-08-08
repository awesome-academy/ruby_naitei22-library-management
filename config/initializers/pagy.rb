# config/initializers/pagy.rb
require "pagy/extras/bootstrap"

# Số bản ghi mặc định mỗi trang
Pagy::DEFAULT[:items] = 10

# Không cho override qua param ?items
Pagy::DEFAULT[:items_param] = false

# Tắt preloading thêm record (nguyên nhân gây 20 bản ghi)
Pagy::DEFAULT[:trim_extra] = false

# Bắt buộc giới hạn limit bằng items
Pagy::DEFAULT[:limit] = Pagy::DEFAULT[:items]

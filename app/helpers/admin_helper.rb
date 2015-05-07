module AdminHelper
 def get_ps_price(orig_price)
		option = PsConfig.where('name = ?', 'domain_price').first
		price = orig_price + ((orig_price / 100)*option.value.to_f)
	end
end 
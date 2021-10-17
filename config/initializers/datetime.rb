class Time

	def short
		strftime("%Y-%m-%d %H:%M")
	end

	def long
		strftime("%Y-%m-%d %H:%M:%S")
	end
end
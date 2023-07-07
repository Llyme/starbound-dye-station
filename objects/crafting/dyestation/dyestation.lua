function init()
	message.setHandler("PutItemsAt", function(_, _, item, offset)
		world.containerPutItemsAt(entity.id(), item, offset)
	end)
end
local MAJOR, MINOR = 'StdUi', 1;
--- @class StdUi
local StdUi = LibStub:NewLibrary(MAJOR, MINOR);

if not StdUi then
	return;
end

function StdUi:SetObjSize(obj, width, height)
	if width then
		obj:SetWidth(width);
	end

	if height then
		obj:SetHeight(height);
	end
end

function StdUi:ApplyBackdrop(frame, type)
	frame:SetBackdrop({
		bgFile = [[Interface\Buttons\WHITE8X8]],
		edgeFile = [[Interface\Buttons\WHITE8X8]],
		edgeSize = 1,
	});

	type = type or 'button';

	frame:SetBackdropColor(
		self.config.backdrop[type].r,
		self.config.backdrop[type].g,
		self.config.backdrop[type].b,
		self.config.backdrop[type].a
	);
	frame:SetBackdropBorderColor(
		self.config.backdrop.border.r,
		self.config.backdrop.border.g,
		self.config.backdrop.border.b,
		self.config.backdrop.border.a
	);
end

function StdUi:ClearBackdrop(frame)
	frame:SetBackdrop(nil);
end
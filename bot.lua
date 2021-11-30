local discordia = require('discordia')
local client = discordia.Client()
local token = io.open("data/token.txt", "r")
local data = {
	reportChannel = "data/reportChannel.txt",
	logChannel = "data/logChannel.txt",
	messageUser = "data/messageUser.txt"
}

client:on('ready', function()
	print('Logged in as '.. client.user.username)
end)

client:on('messageCreate', function(message)
	if message.author.bot then
		return false
	end 

	local report = {
		title = "User's ID:",
		reportFieldName = "Report:",
		attachmentFieldName = "Attachment:",
		footerText = "Some text here.",
		color = 0xe74733
	}

	local reportCommand = {
		setMessage = "set:messagechannel",
		setUserMessage = "set:usermessage",
		setReport = "set:reportchannel",
		setLog = "set:logchannel",
		getCommands = "get:commands"
	}
								-- Commands --

	if message.content == reportCommand.getCommands then
		message:delete()
		message:reply {
			embed = {
				title = "Commands",
				timestamp = discordia.Date():toISO('T', 'Z'),
				fields = {
					{
						name = reportCommand.setMessage,
						value = "Make the bot send any message that will be sent on this channel. Example: 'set:messagechannel Hello guys'.",
						inline = false
					},
					{
						name = reportCommand.setUserMessage,
						value = "Configure some message to send to the user who made report (optional).",
						inline = false
					},
					{
						name = reportCommand.setReport,
						value = "Defines the current channel as a report channel.",
						inline = false
					},
					{
						name = reportCommand.setLog,
						value = "Defines the current channel as a log channel.",
						inline = false
					},
					{
						name = reportCommand.getCommands,
						value = "View current commands.",
						inline= false
					}
				},
				footer = {
					text = report.footerText,
					icon_url = client.user.avatarURL
				},
				color = report.color
			}
		}
	end

								-- Set Log Channel --

	local logFile = io.open(data.logChannel, "r")

	if message.content == reportCommand.setLog then
		if string.match(logFile:read("a"), message.channel.id) then
			message:reply {
				embed = {
					description = "This channel is already configured as a **log channel**.",
					color = report.color,
				}
			}
			message:delete()
			return true
		else
			local logFile2 = io.open(data.logChannel, "w")
			logFile2:write(message.channel.id)
			message:reply {
				embed = {
					description = "The channel " .. message.channel.mentionString ..  " has been configured as a **log channel**.",
					color = report.color,
				}
			}
			message:delete()
			logFile2:close()
			return true
		end
		message:delete()
	end

								-- Set Report Channel --

	local reportFile = io.open(data.reportChannel, "r")
	if message.content == reportCommand.setReport then		
		if logFile:read("L") == nil then
			message:reply {
				embed = {
					description = "You have to set a log channel first.",
					color = report.color
				}
			}
			message:delete()
			return false
		end

		if string.match(reportFile:read("a"), message.channel.id) then
			message:reply {
				embed = {
					description = "This channel is already configured as a **report channel**.",
					color = report.color,
				}
			}
			message:delete()
			return true
		else
			local reportFile2 = io.open(data.reportChannel, "w")
			reportFile2:write(message.channel.id)
			message:reply {
				embed = {
					description = "The channel " .. message.channel.mentionString ..  " has been configured as a report channel.",
					color = report.color,
				}
			}
			message:delete()
			reportFile2:close()
			return true
		end
	end

								-- Send report to Log Channel --

	local userMsgFile = io.open(data.messageUser, "r")
	if message.channel.id == string.match(reportFile:read("a"), message.channel.id) then
		local userFile = userMsgFile:read("a")
		if userFile ~= "" then
			message.author:send(userFile)
		end

		userMsgFile:close()
		if (message.attachments) then
			message.guild:getChannel(logFile:read("L")):send {
				embed = {
					title = report.title,
					description = message.author.mentionString .. " - " .. message.author.id,
					timestamp = discordia.Date():toISO('T', 'Z'),
					image = {
						url = message.attachment.url
					},
					author = {
						name = message.author.tag,
						icon_url = message.author.avatarURL
					},
					fields = {
						{
							name = report.reportFieldName,
							value = "``` " .. message.content .. "```",
							inline = true
						},
						{
							name = report.attachmentFieldName,
							value = "** **",
							inline = false
						},
					},
					footer = {
						text = report.footerText,
						icon_url = client.user.avatarURL
					},
					color = report.color
				}
			}
		else
			message.guild:getChannel(logFile:read("L")):send {
				embed = {
					title = report.title,
					description = message.author.mentionString .. " - " .. message.author.id,
					timestamp = discordia.Date():toISO('T', 'Z'),
					author = {
						name = message.author.tag,
						icon_url = message.author.avatarURL
					},
					fields = {
						{
							name = report.reportFieldName,
							value = "```" .. message.content .. "```",
							inline = true
						},
					},
					footer = {
						text = report.footerText,
						icon_url = client.user.avatarURL
					},
					color = report.color
				}
			}
			logFile:close()
		end
		message:delete()
		reportFile:close()
	end

								-- Set Message Channel --

	if message.content:sub(1, string.len(reportCommand.setMessage)) == reportCommand.setMessage then
		message:reply {
			embed = {
				description = message.content:sub(string.len(reportCommand.setMessage) + 1, 1024),
				timestamp = discordia.Date():toISO('T', 'Z'),
				author = {
					name = message.author.tag,
					icon_url = message.author.avatarURL
				},
				footer = {
					text = report.footerText,
					icon_url = client.user.avatarURL
				},
				color = report.color
			}
		}
		message:delete()
	end

								-- Set Message User --

	if message.content:sub(1, string.len(reportCommand.setUserMessage)) == reportCommand.setUserMessage then
		local getUserText = message.content:sub(string.len(reportCommand.setUserMessage) + 2, 1024)
		local userMsgFile2 = io.open(data.messageUser, "w")
		message:reply {
			embed = {
				description = "**Current message to send to the user**:\n\n" .. getUserText,
				color = report.color,
			}
		}
		userMsgFile2:write(getUserText)
		userMsgFile2:close()
		message:delete()
	end
	return true
end)

client:run("Bot " .. token:read("a"))
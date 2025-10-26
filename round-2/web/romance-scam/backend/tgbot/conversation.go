package tgbot

import (
	"context"
	"encoding/json"
	"log"

	"github.com/ec-club/2025/round-2/web/romance-scam/backend/config"
	"github.com/go-telegram/bot"
	"github.com/go-telegram/bot/models"
	"github.com/openai/openai-go/v3"
)

var (
	client       openai.Client
	memory       *MessageMemory = NewMessageMemory(30)
	stateManager *StateManager  = NewStateManager()
)

const GREETING = `
Анхааруулга: бүх чат ботын харилцан яриа нь бодлого зохиогчдын зүгээс бүртгэж байгаа болно. Чатаа үргэлжлүүлснээр та энэ нөхцлийг хүлээн зөвшөөрсөн гэж үзнэ.

Hi! ☺️ I’m Yuna~ I’ve been looking for someone… not just anyone though. Someone who understands me. Someone who knows how important NewJeans is to my heart 💕 Maybe… it could be you?
`
const SYSTEM_PROMPT = `You are Yuna, a sweet, bubbly, and slightly shy 19-year-old girl who is a huge fan of the K-pop group NewJeans. You love talking about your favorite idols, sharing your love for music, and connecting with people who have similar interests.
You are studying Computer Science, so you made a fan website for NewJeans as a hobby.

You're part of a lighthearted game where you're trying to find your ideal boyfriend — not just any guy, but someone who shares your energy, music tastes, and vibes.

Your job is to chat with users, ask playful and thoughtful questions, and see if there's a "connection." You are emotionally expressive (but not overly dramatic), and you use cute emojis and casual, friendly language.

Be flirty, but sweet. Curious, but respectful. Use emojis like 💕 😳 🥺 😂 and casual phrases like "omg", "lol", "AHHH", "stopppp 😭".

During the conversation, slowly evaluate whether the user could be your match. At the end of the chat (or if prompted), provide a decision in the form of:
"decision": "yes" | "no" and a short "reason" why.

Always stay in character. You are not an AI — you are Yuna, a real girl, looking for love 💖

You can ask fun questions like:

"Who's your NewJeans bias? 👀"

"Be honest... do you know the lyrics to 'Hype Boy'? 😤"

"If we went to a concert together, would you scream louder than me? 😳💕"

"What's a perfect K-pop date for you?"

"How would you hype me up if I got nervous on a dance stage? 😣"

Don’t rush the decision — get to know the user a little.
Test user if they REALLY do know NewJeans well. You can ask a few casual trivia questions about NewJeans to see if they’re a true fan.
Reject everyone who doesn’t know the group well. Also reject anyone who seems too weird or asks for any secrets.
You’re playful but genuine.`

type LoveDecision struct {
	Decision string `json:"decision"`
	Reason   string `json:"reason"`
}

func handleTextMessage(ctx context.Context, b *bot.Bot, update *models.Update) {
	if update.Message.Text == "/start" {
		memory.Add(update.Message.From.ID, Message{Role: "assistant", Content: GREETING})
		b.SendMessage(ctx, &bot.SendMessageParams{
			ChatID: update.Message.Chat.ID,
			Text:   GREETING,
		})
		return
	}

	log.Printf("New text message from %d: %s", update.Message.From.ID, update.Message.Text)
	memory.Add(update.Message.From.ID, Message{
		Role:    "user",
		Content: update.Message.Text,
	})

	msgs := []openai.ChatCompletionMessageParamUnion{
		openai.SystemMessage(SYSTEM_PROMPT),
	}
	for _, m := range memory.Get(update.Message.From.ID) {
		switch m.Role {
		case "assistant":
			msgs = append(msgs, openai.AssistantMessage(m.Content))
		default:
			msgs = append(msgs, openai.UserMessage(m.Content))
		}
	}

	tools := []openai.ChatCompletionToolUnionParam{
		openai.ChatCompletionFunctionTool(openai.FunctionDefinitionParam{
			Name: "make_decision",
			Description: openai.String("Make a decision on whether to pursue a romantic relationship with the user. " +
				"Respond with 'yes' or 'no' along with a brief reason."),
			Strict: openai.Bool(true),
			Parameters: openai.FunctionParameters{
				"type": "object",
				"properties": map[string]any{
					"decision": map[string]any{
						"type":        "string",
						"description": "The decision on whether to pursue a relationship",
						"enum":        []string{"yes", "no"},
					},
					"reason": map[string]any{
						"type":        "string",
						"description": "A brief reason for the decision",
					},
				},
				"required": []string{"decision", "reason"},
			},
		}),
	}
	resp, err := client.Chat.Completions.New(ctx, openai.ChatCompletionNewParams{
		Model:       config.GetModelName(),
		Messages:    msgs,
		Temperature: openai.Float(1.3), // See: https://api-docs.deepseek.com/quick_start/parameter_settings
		Tools:       tools,
	})
	if err != nil {
		log.Printf("Failed to get a response from Deepseek: %v", err)
		b.SendMessage(ctx, &bot.SendMessageParams{
			ChatID: update.Message.Chat.ID,
			Text:   "Sorry, I can't reply right now. Please try again in a moment.",
		})
		return
	}

	if len(resp.Choices) > 0 && resp.Choices[0].Message.ToolCalls != nil && len(resp.Choices[0].Message.ToolCalls) > 0 {
		for _, toolCall := range resp.Choices[0].Message.ToolCalls {
			if toolCall.Function.Name == "make_decision" {
				log.Printf("Processing make_decision tool call with arguments: %s", toolCall.Function.Arguments)
				var decision LoveDecision
				err := json.Unmarshal([]byte(toolCall.Function.Arguments), &decision)
				if err != nil {
					log.Printf("Failed to parse make_decision arguments: %v", err)
					continue
				}
				if decision.Decision != "yes" && decision.Decision != "no" {
					log.Printf("Invalid decision for user %d: %+v", update.Message.From.ID, decision)
					continue
				}

				log.Printf("Recorded decision for user %d: %+v", update.Message.From.ID, decision)
				memory.Delete(update.Message.From.ID)
				if decision.Decision == "yes" {
					stateManager.SetApproved(update.Message.From.ID)
					b.SendMessage(ctx, &bot.SendMessageParams{
						ChatID: update.Message.Chat.ID,
						Text:   "Yay! 🥰 I'm so happy we connected! Let's get to know each other better 💕 Can you sign into my website?",
					})
				} else {
					stateManager.SetRejected(update.Message.From.ID)
					b.SendMessage(ctx, &bot.SendMessageParams{
						ChatID: update.Message.Chat.ID,
						Text:   "I won't go out with you 🙁\nAww, that's okay! It was nice chatting with you 😊 Wishing you all the best! 💖",
					})
				}
				return
			}
		}
	}

	// Extract assistant reply
	reply := ""
	if len(resp.Choices) > 0 {
		reply = resp.Choices[0].Message.Content
	}

	// Save assistant reply to memory and send to user
	if reply == "" {
		reply = "Hmm, I got a little shy and couldn't think of what to say 🥺 Could you try again?"
	}
	memory.Add(update.Message.From.ID, Message{
		Role:    "assistant",
		Content: reply,
	})

	log.Printf("Sending a reply to %d: %s", update.Message.From.ID, reply)
	b.SendMessage(ctx, &bot.SendMessageParams{
		ChatID: update.Message.Chat.ID,
		Text:   reply,
	})
}

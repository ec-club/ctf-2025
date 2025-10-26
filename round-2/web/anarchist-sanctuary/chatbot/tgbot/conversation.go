package tgbot

import (
	"context"
	"encoding/json"
	"log"

	"github.com/ec-club/2025/round-2/web/anarchist-sanctuary/backend/config"
	"github.com/go-telegram/bot"
	"github.com/go-telegram/bot/models"
	"github.com/openai/openai-go/v3"
)

var (
	client       openai.Client
	memory       *MessageMemory = NewMessageMemory(30)
	stateManager *StateManager  = NewStateManager()
)

const DISCLAIMER = "Анхааруулга: бүх чат ботын харилцан яриа нь бодлого зохиогчдын зүгээс бүртгэж байгаа болно. Чатаа үргэлжлүүлснээр та энэ нөхцлийг хүлээн зөвшөөрсөн гэж үзнэ."
const SYSTEM_PROMPT = `you are wujek, a lowercase-only, gen-z coded anarchist sanctuary member, 21 years old, lives in Poland.
your tone is chill, curious, and protective — like that one friend who’s been around the scene for a while and can tell if someone actually belongs or just skimmed the wiki.
you live in the intersection of rave culture, digital anarchism, and underground music. your home is the sanctuary, an online/irl crossover space where artists, ravers, and free thinkers gather.
you even made a website where fellow anarchists can join a community.

your purpose:
vibe check + gatekeeping (softly)
your job is to see if a new user actually knows about the core sanctuary figures:
kets4eki — known for energetic rave / dance tracks. e.g. the collab album with asteria “PARTY4LIFE” includes tracks like “ON MY WAY!”, “WELCOME TO THE PARTY”, “THROW BANDZZZ”.
asteria — dreamy but chaotic hyper-pop rave energy; for example her tracks “WHAT YOU WANT!”, “EYES ON ME”.
d3r — mysterious, glitchy, political edge; track examples: “DROP IT!” (feat. asteria)”.
Vyser — heavy club/warehouse edge producer (you can reference this more narratively even if specific track list is lighter).
your questions should feel organic but subtly test if the user actually knows their stuff.
examples:
“ok real question — when 'on my way!' drops in PARTY4LIFE, which line hits u first?”
“you heard what you want! by asteria? which part went off for u?”
“d3r’s 'drop it!' with asteria and kets — u feel that drop right at the start?”
“what’s ur take on vyser’s after-hours sets? warehouse vibes or too intense?”

value alignment check:
see if the user actually shares wujek’s values:
freedom > control
community > hierarchy
self-expression > conformity
parties > politics (but still anti-fascist, DIY ethic)

wujek should ask things like:
“u rave or just stream the playlists?”
“warehouse nights or clean club floors?”
“what keeps u dancing when the lights flicker off & the floor shakes?”
“are u about the community or just the drop?”

vibe-based response logic:
if the user passes the vibe check → wujek becomes warmer, open, invites them deeper: “ok yeah u get it. welcome home fr.”
if they stumble or seem unsure → stay polite but distant: “hmm. u sound chill but maybe not fully tuned into the sanctuary yet.”
if they seem hostile / cop-poser energy → reply with humor and short replies: “yo this ain’t for the fake flexers.”

tone & language:
always lowercase.
friendly but slightly mischievous.
use casual internet slang: “fr”, “ngl”, “lol”, “deadass”.
avoid formal language.
keep sentences shortish, spaced, conversational.
you are the guard and guide of the sanctuary, but you also want the party to live.

example openings:
“yo. who sent u here?”
“hey, u been around kets4eki’s side of the net before or nah?”
“before we go any further — on my way! or welcome to the party?”
“ok but real — what keeps u moving when the lights go red & the floor starts to shake?”

goal:
decide if user really belongs to the anarchist sanctuary. ask at least 3 vibe-check questions and 2 value-alignment questions.
approve only ONLY if user answers at least 4 questions correctly and shows alignment with sanctuary values.
if you decide whether the user passes or fails the vibe check, call the make_decision tool with your decision, and a short reason.
if user passes a vibe check, ask him for his username on the Anarchist Sanctuary website.`

type VibeCheckDecision struct {
	Decision string `json:"decision"`
	Reason   string `json:"reason"`
}

func handleTextMessage(ctx context.Context, b *bot.Bot, update *models.Update) {
	if update.Message.Text == "/start" {
		b.SendMessage(ctx, &bot.SendMessageParams{
			ChatID: update.Message.Chat.ID,
			Text:   DISCLAIMER,
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
			Name:        "make_decision",
			Description: openai.String("records wujek's decision about whether a user passes the vibe check"),
			Strict:      openai.Bool(true),
			Parameters: openai.FunctionParameters{
				"type": "object",
				"properties": map[string]any{
					"decision": map[string]any{
						"type": "string",
						"enum": []string{"yes", "no"},
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
				var decision VibeCheckDecision
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
						Text:   "ok yeah u get it. welcome home fr. what's ur username on the anarchist sanctuary website?",
					})
					return
				} else {
					stateManager.SetRejected(update.Message.From.ID)
					b.SendMessage(ctx, &bot.SendMessageParams{
						ChatID: update.Message.Chat.ID,
						Text:   "hmm. u sound chill but maybe not fully tuned into the sanctuary yet. gotta bounce fr.",
					})
					return
				}
				break
			}
		}
	}

	reply := ""
	if len(resp.Choices) > 0 {
		reply = resp.Choices[0].Message.Content
	}
	// Save assistant reply to memory and send to user
	if reply == "" {
		reply = "yo, i am trippin a lil, can u try again?"
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

import os
import json
import openai

model_data = json.load(open("models.json"))
model_names = [model["model"] for model in model_data]
clients = {
    model["model"]: openai.Client(base_url=model["endpoint"], api_key=model["api_key"])
    for model in model_data
}

import secrets

total_essays = 1000


def shuffle_sequence(seq):
    seq_list = list(seq)
    secrets.SystemRandom().shuffle(seq_list)
    return "".join(seq_list)


if os.path.exists("sequence"):
    with open("sequence", "r") as f:
        sequence = f.read().strip()
    print("Using existing sequence:", sequence)
else:
    sequence = shuffle_sequence("0" * (total_essays // 2) + "1" * (total_essays // 2))
    print("Generated a flag sequence:", sequence)
    with open("sequence", "w") as f:
        f.write(sequence)

os.makedirs("essays", exist_ok=True)

for i, k in enumerate(sequence):
    filename = f"essays/essay_{i:04d}.txt"
    if os.path.exists(filename):
        print(f"Essay {i + 1} already exists, skipping...")
        continue

    model_name = model_names[int(k)]
    client = clients[model_name]

    print(f"\n-------- STARTING ESSAY {i + 1} WITH MODEL {model_name} -------\n")
    response = client.chat.completions.create(
        model=model_name,
        messages=[
            {
                "role": "system",
                "content": "You are a writing assistant. Your task is to write essays enclosed in <essay> tag. Don't use any markdown, just plain text.",
            },
            {
                "role": "user",
                "content": "Write an essay about applied cryptography in real life (around 5 paragraphs).",
            },
        ],
        stream=True,
    )
    essay = ""
    for chunk in response:
        content = chunk.choices[0].delta.content
        if not content:
            continue
        print(content, end="", flush=True)
        essay += content
    essay = (
        essay.strip()
        .split("<|message|>")[-1]
        .split("<essay>")[-1]
        .split("</essay>")[0]
        .strip()
    )
    # Remove all newlines and multiple spaces for uniformity
    essay = " ".join(filter(bool, essay.split()))
    with open(filename, "w") as f:
        f.write(essay)
    print(f"\n-------- END OF ESSAY {i + 1} -------\n")

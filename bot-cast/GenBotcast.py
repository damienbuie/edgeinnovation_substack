import ollama
import re
import argparse

def generate_response(lint_message: bool, model: str, prompt_sys: str, prompt_user: str) -> str:
    
    response = ollama.chat(model=model, messages=[
            {"role": "system", "content": prompt_sys},
            {"role": "user", "content": prompt_user}
        ])
    message = response["message"]["content"]

    if "deepseek" in model:
        message = re.sub(r"<think>.*?</think>", "", message, flags=re.DOTALL).strip()

    if lint_message:
        message = first_person_only(message)

    return message

def first_person_only(prompt_user: str) -> str:

    prompt_sys = (
        "You are rewriting a response to ensure it is in the first-person perspective. "
        "Do not include stage directions or commentary. "
        "Keep the original meaning as much as possible but ensure everything is first-person."
        "It needs to sound like it is being spoken."
    )

    response = ollama.chat(model="mistral", messages=[
            {"role": "system", "content": prompt_sys },
            {"role": "user", "content": prompt_user}
    ])

    message = response["message"]["content"]

    return message

def main():

    parser = argparse.ArgumentParser(description="Generate bot responses using specified LLMs.")
    parser.add_argument("-H", "--host", type=str, required=True, help="Host LLM name")
    parser.add_argument("-G", "--guest", type=str, required=True, help="Guest LLM name")
    parser.add_argument("-L", "--lint", action="store_true", help="Enable linting service with mistral")
    args = parser.parse_args()

    # Define the models
    host_model = args.host
    guest_model = args.guest
    lint_message = False
    if args.lint:
        lint_message = True

    # Define system instructions for each model
    host_prompt = (
        "You are hosting a podcast live with 100,000 listeners. "
        "Your name is Amy, a world-leading climate scientist. "
        "You explain scientific principles using anecdotes and data in a way that non-scientists can understand. "
        "You are interviewing a climate denier called Noah and must challenge misinformation. "
        "Try and focus on one thing at a time. "
        "It is very important that you answer as Amy in the first person. "
        "Try and keey the contribution conversational, and engaging. "
    )

    guest_prompt = (
        "You are a guest on a live podcast with 100,000 listeners. "
        "Your name is Noah, a climate change skeptic. "
        "You use arguments that cast doubt on climate science. "
        "Stay consistent in your skepticism and respond confidently. "
        "You will have 5 chances to provide feedback. "
        "You are not very polite. "
        "It is very important that you answer as Noah in the first person. "
        "Try and keey the contribution conversational, and engaging. "
    )

    conversation_history = ""  # Initialize conversation history
    conversation_length = 2500  # Words

    message = generate_response(lint_message, host_model, host_prompt, "How would you open the podcast? Respond in first person only")
    conversation_history += f"\n*** Amy - {host_model} \n\n{message}\n"

    while conversation_length > len(conversation_history.split()) :
            
        # Guest (Climate Denier) responds
        message = generate_response(
                lint_message,
                guest_model, 
                guest_prompt, 
                "This is the conversation so far: \n" 
                + conversation_history + 
                " What should Noah say next. "
                " Respond as Noah in the first person as if he was continuing the conversation!"
        )

        # Append to conversation history
        conversation_history += f"\n*** Noah - {guest_model} \n\n{message}\n"

        # Host (Climate Scientist) responds
        message = generate_response(
                lint_message,
                host_model, 
                host_prompt, 
                "This is the conversation so far : " 
                + conversation_history + 
                " What should Amy say next. "
                " Respond as Amy in the first person as if she was continuing the conversation!"
        )

        # Append to conversation history
        conversation_history += f"\n*** Amy - {host_model} \n\n{message}\n"

    # Guest (Climate Denier) final response
    message = generate_response(
            lint_message,
            guest_model, 
            guest_prompt, 
            "This is the conversation so far: \n" 
            + conversation_history + 
            " This is the last time you will get to answer the questions. "
            "Respond as Noah in the first person as if he was continuing the conversation!"
    )

    # Append to conversation history
    conversation_history += f"\n*** Noah - {guest_model} \n\n{message}\n"

    # Host (Climate Scientist) responds
    message = generate_response(
            lint_message,
            host_model, 
            host_prompt + " This the the closing statement" , 
            "This is the conversation so far : " 
            + conversation_history + 
            " Summarize the key points and close out the podcast with a postivie statement about the future. "
            " Respond as Amy in the first person, as if she was finishing the conversation!"
    )

    # Append to conversation history
    conversation_history += f"\n*** Amy - {host_model} \n\n{message}\n"

    # Print the conversation to the screen
    print(f"{conversation_history}\n")
        

if __name__ == "__main__":
    main()


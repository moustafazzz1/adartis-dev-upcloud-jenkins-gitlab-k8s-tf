import random
import time
from datetime import datetime

def generate_random_number():
    # Generate a random number between 1 and 100
    return random.randint(1, 100)

def main():
    while True:
        # Get the current date and time
        current_datetime = datetime.now().strftime('%Y-%m-%d %H:%M:%S')

        # Generate a random number
        number = generate_random_number()

        # Print the current date and time along with the random number
        print(f"Current Date Time: {current_datetime}, Random Number: {number}")

        # Wait for 5 seconds
        time.sleep(5)

if __name__ == "__main__":
    main()

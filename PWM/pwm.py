import pandas as pd
import matplotlib.pyplot as plt

# Replace with your filename
filename = "pwm_output.txt"

# Read the tab-separated file, skip initial spaces if any
df = pd.read_csv(filename, sep='\t')


# Print the first few rows to check
print(df.head())

# Plot Time vs PWM_out
plt.figure(figsize=(10, 4))
plt.step(df['Time'], df['PWM_out'], where='post')
plt.xlabel('Time (ns)')
plt.ylabel('PWM Output')
plt.title('PWM Output vs Time')
plt.ylim(-0.1, 1.1)
plt.grid(True)
plt.show()

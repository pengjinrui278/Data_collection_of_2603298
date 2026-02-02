import matplotlib.pyplot as plt

labels = 'CPU', 'Mobile Network', 'Wi-Fi', 'Bluetooth', 'Backlight'
sizes = [35, 30, 25, 7, 3]
explode = (0, 0, 0, 0.1, 0.2)

fig1, ax1 = plt.subplots()

ax1.pie(
    sizes,
    explode=explode,
    labels=labels,
    autopct='%1.1f%%',
    shadow=True,
    startangle=90
)

ax1.axis('equal')

plt.show()
# Context Steering

![Static Badge](https://img.shields.io/badge/Context%20Steering-MIT-greem)

## ℹ️ Overview

I first needed to initialize the properties of the vectors based on some given parameters, such as the number of rays used and their length. With the rays, the first one is placed to the right of the enemy, then rotated counterclockwise, with each ray being equal lengths apart. Additionally, I also set up the danger rays and interest rays in the ready function as well. Moreover, they are set up in the character data so they are accessible by all the states.

When calculating the chosen direction for the AI to move, it takes the interest rays and then uses a dot product on the direction to the player, giving the rays closer to the direction a higher value to make that direction more prevalent. After that is done, it considers the danger rays, adding the opposite direction of the collided danger ray to the chosen directions. Moreover, based on how close the collided object is, the stronger the reverse ray is, scaling based on a logarithmic graph. Certain collision layers can also be considered higher priority based on changing integer values.

The enemy has 5 states: idle, chase, surround, out of sight, tackle. These states work together to make a believable and dynamic AI.

### ✍️ Author

Hi, I'm [Colin Thai](https://github.io)! With my platformer relying heavily on immersive enemy AI, I knew that a context steering agent would be the best way to have complex and engaging AI. Though quite an arduous task with the complex linear algebra, a presentable project is finally done.

## 🌟 Highlights

Debug rays turned on
![](https://github.com/totallyacoolguy/Context-Steering/blob/main/GIFS/DEBUG_RAYS_ENEMY.gif)

Multiple enemies at the same time with debug rays off
![](https://github.com/totallyacoolguy/Context-Steering/blob/main/GIFS/MULTIPLE_ENEMY_RUN.gif)

## ⬇️ Installation

All you need is Godot 4.3 installed and to clone the repo to see the AI.

```bash
git clone https://github.com/totallyacoolguy/Context-Steering.git
```

As a note, the program runs on the main node, so make your changes there to see the effects.

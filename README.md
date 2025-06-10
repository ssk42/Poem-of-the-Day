# Poem of the Day Widget

## Overview

**Poem of the Day** is an iOS widget that delivers a daily dose of poetry directly to your home screen. Featuring a curated selection of classic and contemporary poems, this app aims to inspire, uplift, and add a touch of beauty to your everyday life. The app includes support for widgets, allowing you to view new poems without even opening the app, making it an easy and accessible way to enjoy poetry.

## Questions

**If you have questions or issues**: Please file an issue here on the Github. I'll happily answer anything, thank you!

## Features

- **Daily Poems**: Receive a new, hand-picked poem every day.
- **Widget Support**: Add a widget to your home screen to easily view the daily poem.
- **Save Favorites**: Mark poems as favorites for quick access later.
- **Offline Access**: Revisit previously viewed poems even when offline.
- **Simple and Elegant UI**: A minimalist design to let the beauty of the words take center stage.

## Installation

1. Clone this repository.
   ```bash
   git clone https://github.com/yourusername/poem-of-the-day-widget.git
   ```
2. Open the project in Xcode.
   ```bash
   cd poem-of-the-day-widget
   open 'Poem of the Day.xcodeproj'
   ```
3. Run the app using the iOS Simulator or a physical device.

## Usage

1. **Add the Widget to Your Home Screen**: After installing the app, add the widget by pressing and holding on your home screen, then tapping the '+' button and selecting "Poem of the Day".
2. **View Daily Poems**: Every day, a new poem will be delivered directly to the widget, offering a fresh perspective and moment of reflection.
3. **Save Your Favorites**: Tap on a poem to save it as a favorite. You can view all your saved poems in the Favorites section of the app.

## API

The app uses the **PoetryDB** API to fetch daily poems. For more details on the API, visit [PoetryDB](https://poetrydb.org/).

## Project Structure

- **Poem_Of_The_Day_Widget.swift**: Contains the widget's logic, including fetching data and updating the timeline.
- **Provider**: Manages the timeline updates and data fetching from PoetryDB.
- **Views**: Responsible for the UI of the widget, display

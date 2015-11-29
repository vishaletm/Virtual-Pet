﻿using UnityEngine;
using System.Collections;
using UnityEngine.UI;

namespace PersonalScripts
{
    class World_MiniGame_02_UI: MonoBehaviour
    {
        public static World_MiniGame_02_UI SP;
        public static int score;
        public Button[] buttons;
        public GameObject optionsPanel;
        public Button pauseBtn;
        public Button restartBtn;
        public Button quitBtn;
        public Button closeOptionsBtn;
        public Button tryAgainBtn;
        GameObject gameOver;

        private int bestScore = 0;

        void Awake()
        {
            SP = this;
            score = 0;
            bestScore = PlayerPrefs.GetInt("BestScorePlatforms", 0);
            gameOver = GameObject.FindGameObjectWithTag("LevelManager");
            gameOver.gameObject.SetActive(false);
            SetButtons();
            SetPanels();
        }

        void OnGUI()
        {
            GUILayout.Space(3);
            GUILayout.Label(" Score: " + score);
            GUILayout.Label(" Highscore: " + bestScore);

            if (World_MiniGame_02.gameState == GameState.gameover)
            {
                GUILayout.BeginArea(new Rect(0, 0, Screen.width, Screen.height));

                GUILayout.BeginHorizontal();
                GUILayout.FlexibleSpace();
                GUILayout.BeginVertical();
                GUILayout.FlexibleSpace();

                //GUILayout.Label("Game over!");
                if (score > bestScore)
                {
                    GUI.color = Color.red;
                    GUILayout.Label("New highscore!");
                    GUI.color = Color.white;
                }
                //if (GUILayout.Button("Try again"))
                //{
                //    Application.LoadLevel(Application.loadedLevel);
                //}
                gameOver.gameObject.SetActive(true);
                tryAgainBtn.gameObject.SetActive(true);

                GUILayout.FlexibleSpace();
                GUILayout.EndVertical();
                GUILayout.FlexibleSpace();
                GUILayout.EndHorizontal();
                GUILayout.EndArea();

            }
        }

        public void CheckHighscore()
        {
            if (score > bestScore)
            {
                PlayerPrefs.SetInt("BestScorePlatforms", score);
            }
        }

        public void SetButtons()
        {
            if (buttons.Length == 0)
            {
                buttons = GameObject.FindObjectsOfType<Button>();
            }
            foreach (var button in buttons)
            {
                string buttonName = button.name;
                switch (buttonName)
                {
                    case "Options":
                        pauseBtn = button;
                        button.onClick.AddListener(delegate
                        {
                            Time.timeScale = 0;
                            pauseBtn.gameObject.SetActive(false);
                            optionsPanel.gameObject.SetActive(true);
                        });
                        break;
                    case "RestartBtn":
                        restartBtn = button;
                        break;
                    case "ExitBtn":
                        quitBtn = button;
                        break;
                    case "CloseOptionsBtn":
                        closeOptionsBtn = button;
                        button.onClick.AddListener(delegate
                        {
                            Time.timeScale = 1;
                            optionsPanel.gameObject.SetActive(false);
                            pauseBtn.gameObject.SetActive(true);
                        });
                        break;
                    case "TryAgainBtn":
                        tryAgainBtn = button;
                        tryAgainBtn.gameObject.SetActive(false);
                        button.onClick.AddListener(delegate
                        {
                            tryAgainBtn.gameObject.SetActive(false);
                            Application.LoadLevel(Application.loadedLevel);
                        });
                        break;
                }
            }
        }

        public void SetPanels()
        {
            if (optionsPanel == null)
            {
                optionsPanel = GameObject.FindGameObjectWithTag("Panel");
                optionsPanel.gameObject.SetActive(false);
            }
        }
    }
}

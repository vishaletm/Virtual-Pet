﻿// Project: Pet Pals
// File: World_MiniGame_01_UI.cs
// Modification History:
// Author           Date
// Jean-Baptiste	11/27/15
// Jean-Baptiste	11/28/15
// Labus			11/29/15
// Mirvil			11/30/15

using UnityEngine;
using System.Collections;
using PersonalScripts;
using UnityEngine.UI;


class World_MiniGame_01_UI : DynamicButtonAssignment
{
    Button optionsBtn;
    Slider[] sliders;
    Slider volumeSlider;
    int outfitIndex = 0;

    public override void SetupButtons()
    {

        if (_buttons == null)
        {
            _buttons = GameObject.FindObjectsOfType<Button>();
        }

        // Checks names of buttons and adds listeners accordingly
        for (int i = 0; i < _buttons.Length; i++)
        {
            string btnName = _buttons[i].name;

            if (btnName == "JumpBtn")
            {
                _buttons[i].onClick.AddListener(delegate
                {
                    GameObject.FindObjectOfType<Player1StickMovement>().GetComponent<Player1StickMovement>().Jump(3f);
                });
            }
            if (btnName == "Attack1Btn")
            {
                _buttons[i].onClick.AddListener(delegate
                {
                    _player.Attack(1);

                });
            }
            if (btnName == "Attack2Btn")
            {
                _buttons[i].onClick.AddListener(delegate
                {
                    _player.Attack(2);
                });
            }
            if (btnName == "Outfit")
            {
                _buttons[i].onClick.AddListener(delegate
                {
                    outfitIndex++;
                    if (outfitIndex > 3)
                    {
                        outfitIndex = 0;
                    }
                    _player.ChangeIntoSpecificFit(outfitIndex);
                });
            }
            if (btnName == "Options")
            {
                optionsBtn = _buttons[i];
                _buttons[i].onClick.AddListener(delegate
                {
                    Time.timeScale = 0;
                    optionsBtn.gameObject.SetActive(false);
                    optionsPanel.gameObject.SetActive(true);
                });
            }
            if (btnName == "CloseOptionsBtn")
            {
                _buttons[i].onClick.AddListener(delegate
                {
                    Time.timeScale = 1;
                    optionsPanel.gameObject.SetActive(false);
                    optionsBtn.gameObject.SetActive(true);
                });
            }
            if (btnName == "RestartBtn")
            {
                _buttons[i].onClick.AddListener(delegate
                {
                    Time.timeScale = 1;
                    optionsPanel.gameObject.SetActive(false);
                    optionsBtn.gameObject.SetActive(true);
                    Application.LoadLevel(Application.loadedLevel);
                });
            }
            if (btnName == "ExitBtn")
            {
                _buttons[i].onClick.AddListener(delegate
                {
                    World_MiniGame_01 wmg1 = GameObject.Find("managers").GetComponentInChildren<World_MiniGame_01>();
                    wmg1.Quit();
                    Time.timeScale = 1;
                    Application.LoadLevel("Main");
                });
            }
        }
        SetupSliders();
    }

    public void SetupPanels()
    {
        if (_panels == null)
        {
            _panels = GameObject.FindGameObjectsWithTag("Panel");
        }
        foreach (var panel in _panels)
        {
            string panelName = panel.name;
            panel.gameObject.SetActive(false);
            switch (panelName)
            {
                case "OptionsPanel":
                    optionsPanel = panel;
                    break;
            }
        }
    }

    void SetupSliders()
    {
        if (sliders == null)
        {
            sliders = GameObject.FindObjectsOfType<Slider>();
            foreach (var slider in sliders)
            {
                string sliderName = slider.name;
                switch (sliderName)
                {
                    case "VolumeSlider":
                        volumeSlider = slider;
                        slider.onValueChanged.AddListener(delegate
                        {
                            AudioSource music = GameObject.Find("managers").GetComponentInChildren<AudioSource>();
                            music.volume = volumeSlider.value;
                        });
                        break;
                }
            }
        }
    }
}


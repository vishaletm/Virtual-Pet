﻿using UnityEngine;
using System.Collections;

public class WeaponHandler : MonoBehaviour 
{
    public GameObject[] _weapons;
    public int _currentWeaponIndex;
    private BoxCollider[] _collider; // used as rigidBody for all Weapons
    private Animator _anim;
    // power values of each weapon
    public int _swordPower = 17;
    public int _axePower = 20;
    public int _fistPower = 10;
    enum WeaponType
    {
        Hands = 0,
        Sword,
        Axe
    }

    public void DisableAllWeapons()
    {
        // same as no weapons
        _currentWeaponIndex = 0;
        for (int i = 0; i < _weapons.Length; i++)
        {
            _weapons[i].SetActive(false);
        }
    }
    void Awake()
    {
        _weapons = GameObject.FindGameObjectsWithTag("Weapon");
        _anim = GetComponent<Animator>();
        DisableAllWeapons();
        DisableEnableColliders(false);
        ChangeWeapons();
        ChangeWeapons();
        ChangeWeapons();
    }

    void OnTriggerEnter(Collider other)
    {
        // determines how much harm to deal
        int damageAmount = 0;
        switch(_currentWeaponIndex)
        {
            case (int)WeaponType.Hands:
                damageAmount = _fistPower;
                break;
            case (int)WeaponType.Sword:
                damageAmount = _swordPower;
                break;
            case (int)WeaponType.Axe:
                damageAmount = _axePower;
                break;
        }
        // only enemies and objects are damageable
        EnemyHealth enemyHealth;
        ObjectHealth objectHealth;
        if (other.tag == "Damageable")
        {
            enemyHealth = other.GetComponent<EnemyHealth>();
            objectHealth = other.GetComponent<ObjectHealth>();
            if (enemyHealth == null)
                objectHealth.TakeDamage(damageAmount, _weapons[_currentWeaponIndex].transform.position);
            else
                enemyHealth.TakeDamage(damageAmount, _weapons[_currentWeaponIndex].transform.position);
        }
    }

    public void Attack(int attackType)
    {
        if (attackType == 1)
        {
            DisableEnableColliders(true);
            _anim.SetTrigger("Attack1");
        }
        if (attackType == 2)
        {
            DisableEnableColliders(true);
            _anim.SetTrigger("Attack2");
        }
    }
    void FixedUpdate()
    {
        // if either of the attack animations are playing enable colliders
        // disable elsewise
        if (this._anim.GetCurrentAnimatorStateInfo(0).IsName("A_attack_01") || this._anim.GetCurrentAnimatorStateInfo(0).IsName("A_attack_02"))
        {
            DisableEnableColliders(true);
        }
        else
        {
            DisableEnableColliders(false);
        }


    }

    public void ChangeWeapons()
    {
        ChangeWeapons(0);
    }
    public void ChangeWeapons(int index, bool loop = true)
    {
        // NOTE: In order for this logic to work players must initially have both
        // weapons activated, once the list is acquired we can then loop through the
        // array of weapon objects
        // must be enabled to be recognized next iteration
        DisableEnableColliders(true);
        // save current index and clear weapons
        int tempWeapon = _currentWeaponIndex;
        int newIndex = (tempWeapon + 1) % 3; // there are 3 head types
        DisableAllWeapons();
        //Debug.Log("New Index " + newIndex + " NumWeapons: " + _weapons.Length);
        if (loop)
        {
            Debug.Log(newIndex);
            _weapons[newIndex].SetActive(true);
            _currentWeaponIndex = newIndex;
        }
        else
        {
            _weapons[index].SetActive(true);
            _currentWeaponIndex = index;
        }
        // gets the respective box colliders and disables it
        DisableEnableColliders(false);
    }

    void DisableEnableColliders(bool enable)
    {
        _collider = _weapons[_currentWeaponIndex].GetComponents<BoxCollider>();
        if (!enable)
        {
            foreach (Collider colli in _collider)
            {
                colli.enabled = false;
            }
        }
        else
        {
            foreach (Collider colli in _collider)
            {
                colli.enabled = true;
            }
        }
    }
}

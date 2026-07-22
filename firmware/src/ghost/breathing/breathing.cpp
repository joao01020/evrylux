#include "breathing.h"

#include <Arduino.h>



void Breathing::reset()
{

    state = State::INHALE;


    offset = 0;


    direction = 1;


    timer = millis();


    stateTimer = millis();

}



void Breathing::update()
{

    unsigned long now = millis();



    switch(state)
    {


        // =========================
        // INSPIRAR
        // =========================

        case State::INHALE:


            if(now - timer > 1200)
            {

                offset++;


                timer = now;



                if(offset >= 2)
                {

                    state = State::HOLD;


                    stateTimer = now;

                }

            }

            break;



        // =========================
        // SEGURA O AR
        // =========================

        case State::HOLD:


            if(now - stateTimer > 1800)
            {

                state = State::EXHALE;

            }

            break;



        // =========================
        // EXPIRAR
        // =========================

        case State::EXHALE:


            if(now - timer > 1500)
            {

                offset--;


                timer = now;



                if(offset <= 0)
                {

                    offset = 0;


                    state = State::REST;


                    stateTimer = now;

                }

            }

            break;



        // =========================
        // DESCANSO
        // =========================

        case State::REST:


            if(now - stateTimer > 2500)
            {

                state = State::INHALE;

            }

            break;


    }

}



int Breathing::getOffset()
{

    return offset;

}
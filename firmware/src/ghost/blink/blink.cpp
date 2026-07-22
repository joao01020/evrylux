#include "blink.h"



void Blink::reset()
{

    state = State::OPEN;


    eyeHeight = 5;

    previousEyeHeight = 5;


    lastFrame = millis();


    nextBlink =
        millis() + random(3000,7000);


    doubleBlink = false;

}



void Blink::chooseBlink()
{

    int value = random(0,100);


    if(value < 80)
    {

        type = Type::NORMAL;

    }

    else if(value < 95)
    {

        type = Type::SLOW;

    }

    else
    {

        type = Type::DOUBLE;

    }

}



void Blink::update()
{

    unsigned long now = millis();



    switch(state)
    {


        case State::OPEN:


            if(now > nextBlink)
            {

                chooseBlink();


                state = State::CLOSING;


                lastFrame = now;

            }

            break;



        case State::CLOSING:
        {

            int speed = 60;


            if(type == Type::SLOW)
                speed = 120;



            if(now - lastFrame > speed)
            {

                eyeHeight--;


                if(eyeHeight <= 1)
                {

                    eyeHeight = 1;


                    state = State::CLOSED;

                }


                lastFrame = now;

            }

            break;

        }



        case State::CLOSED:
        {

            int hold = 120;


            if(type == Type::SLOW)
                hold = 250;



            if(now - lastFrame > hold)
            {

                state = State::OPENING;


                lastFrame = now;

            }

            break;

        }



        case State::OPENING:
        {


            if(now - lastFrame > 60)
            {

                eyeHeight++;


                if(eyeHeight >= 5)
                {

                    eyeHeight = 5;



                    if(type == Type::DOUBLE && !doubleBlink)
                    {

                        doubleBlink = true;


                        state = State::CLOSING;


                    }

                    else
                    {

                        state = State::OPEN;


                        nextBlink =
                            now + random(3000,7000);


                        doubleBlink = false;

                    }

                }


                lastFrame = now;

            }

            break;

        }

    }

}



int Blink::getEyeHeight()
{

    return eyeHeight;

}



bool Blink::hasChanged()
{

    if(
        eyeHeight != previousEyeHeight
    )
    {

        previousEyeHeight = eyeHeight;

        return true;

    }


    return false;

}
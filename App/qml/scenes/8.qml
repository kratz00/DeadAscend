import QtQuick 2.0

import Qak 1.0
import Qak.Tools 1.0
import Qak.QtQuick 2.0

import ".."
import "."

Base {
    id: scene

    ready: store.isLoaded && elevatorDoor.ready

    onReadyChanged: {

        if(game.helpCalled) {
            miniGameMode = true
            elevatorDoor.setActiveSequence('close')
            game.setText(" "," ","...","Something is wrong","I can feel it","I can hear zombies","A lot of zombies!")
        } else
            elevatorDoor.setActiveSequence('opened-wait-close')
    }

    anchors { fill: parent }

    property bool miniGameMode: false
    property bool miniGamePaused: false

    Store {
        id: store
        name: "level"+sceneNumber
    }

    Component.onCompleted: {
        store.load()
        showExit()

        var sfx = core.sounds
        sfx.add("level"+sceneNumber,"shotgun",App.getAsset("sounds/shotgun_shot_01.wav"))
        sfx.add("level"+sceneNumber,"zombie_moan_1",App.getAsset("sounds/zombie_moan_01.wav"))
        sfx.add("level"+sceneNumber,"zombie_moan_2",App.getAsset("sounds/zombie_moan_02.wav"))
        sfx.add("level"+sceneNumber,"zombie_moan_3",App.getAsset("sounds/zombie_moan_03.wav"))

    }

    Component.onDestruction: {
        store.save()

        for(var zid in zombies) {
            zombies[zid].destroy()
        }
    }

    function showExit() {
        game.showExit(515,300,2000,"down")
    }


    // MINI GAME
    property var zombies: ({})
    property int nextZid: 0
    onMiniGameModeChanged: {
        if(miniGameMode) {
            zombieSpawnTimer.start()
        }
    }

    Timer {
        id: zombieSpawnTimer
        repeat: true
        interval: 4000
        onTriggered: {

            nextZid++

            var attrs = {
                x: scene.halfWidth-100,
                y: scene.halfHeight+100,
                zid: nextZid,
                type: "0"+Aid.randomRangeInt(1,4)
            }

            game.incubator.now(zombieComponent, zField, attrs, function(o){
                App.debug('Spawned zombie',o.zid)
                scene.zombies[o.zid] = o
            })

            // Next spawn
            interval = Aid.randomRangeInt(100,600)
        }
    }

    Component {
        id: zombieComponent
        Entity {
            id: tt
            width: 1; height: 1
            property string zid: ""
            property string type: "00"
            z: y > 450 ? y : -3-parseInt(zid)

            signal died()

            onDied: {
                tt.z = -900
            }

            ImageAnimation {
                id: zwalk
                x: 0.5; y: -height
                //anchors.centerIn: parent
                running: true
                visible: running
                paused: !visible || scene.miniGamePaused

                MouseArea {
                    anchors { fill: parent }
                    onClicked: {
                        sounds.play('shotgun')
                        sounds.play("zombie_moan_3")
                        tt.mover.stop()
                        if(tt.type === "02" || tt.type === "04" )
                            zdie.x = -zwalk.halfWidth
                        zwalk.running = false
                    }
                }
            }

            ImageAnimation {
                id: zdie
                x: 0.5; y: -height
                //anchors.centerIn: parent
                visible: !zwalk.animating
                paused: !visible || scene.miniGamePaused
                onSequenceNameChanged: {
                    if(sequenceName === "dead")
                        tt.died()
                }
            }

            Component.onCompleted:  {
                var wseqs = []
                var dseqs = []
                if(type === "01") {
                    wseqs.push({
                        name: "walk",
                        frames: [1,2,3,4,5,6,7,8,9,10],
                        to: { "walk":1}
                    })

                    dseqs.push({
                        name: "die",
                        frames: [1,2,3,4,5],
                        to: { "dead":1}
                    })
                    dseqs.push({
                        name: "dead",
                        frames: [5]
                    })
                    zwalk.width = 146
                    zwalk.height = 249
                    zdie.width = 222
                    zdie.height = 242
                }
                if(type === "02") {
                    wseqs.push({
                        name: "walk",
                        frames: [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16],
                        to: { "walk":1}
                    })

                    dseqs.push({
                        name: "die",
                        frames: [1,2,3,4,5,6,7],
                        to: { "dead":1}
                    })
                    dseqs.push({
                        name: "dead",
                        frames: [7]
                    })
                    zwalk.width = 137
                    zwalk.height = 313
                    zdie.width = 265
                    zdie.height = 316
                }
                if(type === "03") {
                    wseqs.push({
                        name: "walk",
                        frames: [1,2,3,4,5,6,7,8,9,10,11,12],
                        to: { "walk":1}
                    })

                    dseqs.push({
                        name: "die",
                        frames: [1,2,3,4,5],
                        to: { "dead":1}
                    })
                    dseqs.push({
                        name: "dead",
                        frames: [5]
                    })
                    zwalk.width = 150
                    zwalk.height = 210
                    zdie.width = 208
                    zdie.height = 160
                }
                if(type === "04") {
                    wseqs.push({
                        name: "walk",
                        frames: [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15],
                        to: { "walk":1}
                    })

                    dseqs.push({
                        name: "die",
                        frames: [1,2,3,4,5,6,7],
                        to: { "dead":1}
                    })
                    dseqs.push({
                        name: "dead",
                        frames: [7]
                    })
                    zwalk.width = 113
                    zwalk.height = 285
                    zdie.width = 210
                    zdie.height = 271
                }
                zwalk.sequences = wseqs
                zwalk.source = App.getAsset("sprites/zombies/attack_zombies/"+type+"/walk/0001.png")
                zwalk.defaultFrameDelay = 140
                zwalk.setActiveSequence('walk')

                zdie.sequences = dseqs
                zdie.source = App.getAsset("sprites/zombies/attack_zombies/"+type+"/headless_fall/0001.png")
                zdie.defaultFrameDelay = 140

                var sp = { x: tt.x, y: tt.y }
                var l = !!Math.floor(Math.random() * 2) // NOTE Random bool
                var xm = 0, ym = 0
                for(var i = 0; i <= 10; i++) {



                    if(i == 0) {
                        xm = l ? -180 : 200
                        ym = Aid.randomRangeInt(5,10)
                    } else if(i == 1) {
                        xm += l ? Aid.randomRangeInt(-100,-90) : Aid.randomRangeInt(200,230)
                        ym += Aid.randomRangeInt(5,10)
                    } else {
                        xm += l ? Aid.randomRangeInt(-10,180) : Aid.randomRangeInt(-180,10)
                        ym += Aid.randomRangeInt(100,200)
                    }

                    tt.mover.pushMove(sp.x+xm,sp.y+ym)
                }
                tt.mover.duration = 60000
                tt.mover.startMoving()
            }

        }
    }

    /*
    MouseArea {
        anchors { fill: parent }
        z: -10
        onClicked: {
            var a = [
                "Nah. Not really interesting",
                "Not of any use",
                "It's actually a bit warm in here",
                "There's almost too quiet..."
            ]
            game.setText(Aid.randomFromArray(a))
        }
    }*/

    /*
    Area {
        stateless: true

        name: "exit_complete"

        onClicked: game.goToScene("ending")
    }*/

    Item {
        id: zField
        anchors { fill: parent }

        Area {
            z: -2
            stateless: true

            name: "casing_inside"

        }

        Area {
            z: -1
            stateless: true

            name: "casing"

        }

        Area {
            id: sateliteDish
            name: "satelite_dish"
            stateless: true

            description: "That's definitely the antenna dish for the radio"

        }

        Area {
            id: sateliteBox
            name: "satelite_box"
            stateless: true

            description: [ "The box has a socket. It could be something like an external power supply for the antenna", "Maybe to give it extra range?" ]
        }

        Area {
            id: sateliteFuelCell
            name: "satelite_fuel_cell"
            stateless: true
            visible: game.fuelCellConnected
        }


        DropSpot {
            x: sateliteDish.x; y: sateliteDish.y
            width: sateliteFuelCell.x + sateliteFuelCell.width - sateliteDish.x
            height: sateliteFuelCell.y + sateliteFuelCell.height - sateliteDish.y

            keys: [ "fuel_cell" ]

            name: "antenna_drop"

            enabled: !game.fuelCellConnected

            onDropped: {

                core.sounds.play("tick")

                if(game.fuelCellCharged) {
                    game.fuelCellConnected = true

                    drop.accept()
                    var o = drag.source

                    game.blacklistObject(o.name)
                    game.setText("Good work survivour. The antenna is now powered. This should give some extra range")

                } else {
                    game.setText("The fuel cell is out of power. It'll be hard to get it charged under these circumstances")
                }

            }

        }

        AnimatedArea {

            id: elevatorDoor

            name: "elevator_door_8"

            clickable: !animating
            stateless: true

            visible: true
            run: false
            paused: !visible || (scene.paused)

            source: App.getAsset("sprites/elevator_assets/doors/floor_8/move/0001.png")

            defaultFrameDelay: 100

            sequences: [
                {
                    name: "closed",
                    frames: [1]
                },
                {
                    name: "open",
                    frames: [1,2,3,4,5,6],
                    to: { "opened":1 }
                },
                {
                    name: "open-show-panel",
                    frames: [1,2,3,4,5,6],
                    to: { "opened":1 }
                },
                {
                    name: "close",
                    frames: [1,2,3,4,5,6],
                    reverse: true,
                    to: { "closed":1 }
                },
                {
                    name: "opened-wait-close",
                    frames: [6],
                    reverse: true,
                    to: { "close":1 },
                    duration: 1000
                },
                {
                    name: "opened",
                    frames: [6]
                },
            ]

            onClicked: {
                setActiveSequence("open-show-panel")
            }

            onFrame: {
                App.debug(sequenceName, frame )
                if(sequenceName === "open-show-panel" && frame == 4)
                    game.elevatorPanel.show = true
            }
        }

    }


    Connections {
        target: game.elevatorPanel
        onShowChanged: {
            if(game.elevatorPanel.show) {

            } else {
                elevatorDoor.setActiveSequence('close')
            }
        }
    }


    onObjectDropped: {
    }

    onObjectTravelingToInventory: {
    }

    onObjectDragged: {
    }

    onObjectReturned: {
    }

    onObjectAddedToInventory: {
    }

    onObjectRemovedFromInventory: {
    }

}
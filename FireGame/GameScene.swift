//
//  GameScene.swift
//  FireGame
//
//  Created by wubin on 7/13/14.
//  Copyright (c) 2014 wubin. All rights reserved.
//

import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    // define var
    var player:SKSpriteNode = SKSpriteNode()
    var lastYieldTimeInterval:NSTimeInterval = NSTimeInterval()
    var lastUpdateTimerInterval:NSTimeInterval = NSTimeInterval()
    var gyDestroyed:Int = 0
    
    let gyCategory:UInt32 = 0x1 << 1
    let bulletCategory:UInt32 = 0x1 << 0
    
    
    override func didMoveToView(view: SKView) {
        /* Setup your scene here */
        /*let myLabel = SKLabelNode(fontNamed:"Chalkduster")
        myLabel.text = "Hello, World!";
        myLabel.fontSize = 65;
        myLabel.position = CGPoint(x:CGRectGetMidX(self.frame), y:CGRectGetMidY(self.frame));
        
        self.addChild(myLabel)
        */
    }
    
    
   init(size:CGSize){
        super.init(size:size)
        self.backgroundColor = SKColor.blackColor()
        player = SKSpriteNode(imageNamed: "wb")
        
        player.position = CGPointMake(self.frame.size.width/2, player.size.height/2 + 20)
        
        self.addChild(player)
        
        self.physicsWorld.gravity = CGVectorMake(0, 0)
        self.physicsWorld.contactDelegate = self
    }
    
    
    func addGY(){
        var gy:SKSpriteNode = SKSpriteNode(imageNamed: "gy")
        gy.physicsBody = SKPhysicsBody(rectangleOfSize: gy.size)
        gy.physicsBody.dynamic = true
        gy.physicsBody.categoryBitMask = gyCategory
        gy.physicsBody.contactTestBitMask = bulletCategory
        gy.physicsBody.collisionBitMask = 0
        
        let minX = gy.size.width / 2
        let maxX = self.frame.width - gy.size.width / 2
        let rangeX = (maxX - minX)
        let position:CGFloat = CGFloat(UInt(arc4random())) % CGFloat(rangeX) + CGFloat(minX)
        
        gy.position = CGPointMake(position, self.frame.size.height + gy.size.height)
        
        self.addChild(gy)
        
        let minDuration = 2
        let maxDuration = 4
        let rangeDuration = maxDuration - minDuration
        let duration = Int(arc4random()) % rangeDuration + minDuration
        
        
        var actionArray:NSMutableArray = NSMutableArray()
        actionArray.addObject(SKAction.moveTo(CGPointMake(position, -gy.size.height), duration: NSTimeInterval(minDuration)))
        actionArray.addObject(SKAction.runBlock({
            var transition:SKTransition = SKTransition.flipHorizontalWithDuration(0.5)
            var gameOverScene:SKScene = GameOverScene(size: self.size, won: false)
            self.view.presentScene(gameOverScene)
            }))
        actionArray.addObject(SKAction.removeFromParent())
        
        
        
        gy.runAction(SKAction.sequence(actionArray))
        
    }
    
    func updateWithTimeSinceLastUpdate(timeSinceLastUpdate:CFTimeInterval){
        
        lastYieldTimeInterval += timeSinceLastUpdate
        if lastYieldTimeInterval > 1 {
            lastYieldTimeInterval = 0
            addGY()
        }
    }
    
    override func update(currentTime: CFTimeInterval) {
        
        var timeSinceLastUpdate = currentTime - lastUpdateTimerInterval
        lastUpdateTimerInterval = currentTime
        
        if(timeSinceLastUpdate > 1){
            timeSinceLastUpdate = 1/60
            lastUpdateTimerInterval = currentTime
        }
        
        updateWithTimeSinceLastUpdate(timeSinceLastUpdate)
    }

    
    
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        /* Called when a touch begins */
        
       /* for touch: AnyObject in touches {
            let location = touch.locationInNode(self)
            
            let sprite = SKSpriteNode(imageNamed:"Spaceship")
            
            sprite.xScale = 0.5
            sprite.yScale = 0.5
            sprite.position = location
            
            let action = SKAction.rotateByAngle(CGFloat(M_PI), duration:1)
            
            sprite.runAction(SKAction.repeatActionForever(action))
            
            self.addChild(sprite)
        }*/
    }
    
    
    override func touchesEnded(touches: NSSet!, withEvent event: UIEvent!) {
        self.runAction(SKAction.playSoundFileNamed("shoot.mp3", waitForCompletion: false))
        
        var touch:UITouch = touches.anyObject() as UITouch
        var location:CGPoint = touch.locationInNode(self)
        
        var bullet:SKSpriteNode = SKSpriteNode(imageNamed: "bullet")
        bullet.position = player.position
        
        bullet.physicsBody = SKPhysicsBody(circleOfRadius: bullet.size.width/2)
        bullet.physicsBody.dynamic = true
        bullet.physicsBody.categoryBitMask = bulletCategory
        bullet.physicsBody.contactTestBitMask = gyCategory
        bullet.physicsBody.collisionBitMask = 0
        bullet.physicsBody.usesPreciseCollisionDetection = true
        
        var offset:CGPoint = vecSub(location, b: bullet.position)
        
        if(offset.y < 0){
            return
        }
        
        self.addChild(bullet)
        
        var direction:CGPoint = vecNormalize(offset)
        
        var shotLength = vecMult(direction, b: 1000)
        
        var finalDestination:CGPoint = vecAdd(shotLength, b: shotLength)
        
        let velocity = 250
        let moveDuration:Float = Float(self.size.width) / Float(velocity)
        
        var actionArray:NSMutableArray = NSMutableArray()
        actionArray.addObject(SKAction.moveTo(finalDestination, duration:NSTimeInterval( moveDuration)) )
        actionArray.addObject(SKAction.removeFromParent())
        
        bullet.runAction(SKAction.sequence(actionArray))
        
        
    }
    
    
    func didBeginContact(contact: SKPhysicsContact!){
        var bulletBody:SKPhysicsBody
        var gyBody:SKPhysicsBody
        
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            bulletBody = contact.bodyA
            gyBody = contact.bodyB
        } else {
            bulletBody = contact.bodyB
            gyBody = contact.bodyA
        }
        
        if ((gyBody.categoryBitMask & gyCategory) != 0 && (bulletBody.categoryBitMask & bulletCategory) != 0){
            bulletDidCollideWithGY(bulletBody.node as SKSpriteNode, gy: gyBody.node as SKSpriteNode)
        }
        
    }
    
    
    
    
    func bulletDidCollideWithGY(bullet: SKSpriteNode, gy:SKSpriteNode) {
       // println("hit")
        
        bullet.removeFromParent()
        gy.removeFromParent()
        removeFromParent()
        
        gyDestroyed++
        
        if (gyDestroyed > 10) {
            var transition:SKTransition = SKTransition.flipHorizontalWithDuration(1.5)
            var gameOverScene:SKScene = GameOverScene(size: self.size, won: true)
            self.view.presentScene(gameOverScene)

        }
        
    }
    
    
    
    
    
    
    
    func vecAdd(a: CGPoint, b: CGPoint) -> CGPoint{
        return CGPointMake(a.x + b.x, a.y + b.y)
    }
    
    func vecSub(a:CGPoint, b:CGPoint) -> CGPoint {
        return CGPointMake(a.x - b.x, a.y - b.y)
    }
   
    func vecMult(a: CGPoint, b:CGFloat) -> CGPoint {
        return CGPointMake(a.x * b, a.y * b)
    }
    
    func vecLength(a: CGPoint) -> CGFloat{
        return CGFloat(sqrtf( CFloat(a.x)*CFloat(a.x) + CFloat(a.y)*CFloat(a.y) ))
    }
    
    func vecNormalize(a: CGPoint) -> CGPoint {
        let length = vecLength(a)
        return CGPointMake(a.x/length, a.y/length)
    }
    
    
}

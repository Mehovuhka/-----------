// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Shopes{

    struct users{
        address address_user;
        uint role; // 0 - покупатель, 1 - администратор, 2 - продавец
        uint ActiveRole; // текущая роль
        bytes32 password;
    }
    
    struct reqestDown{
        address user;
        address shope; // где работает
        bool status; // status - статус расмотрения админом. По умолчанию false.
        uint approval; // approval - одобрение или откланение админом повышения ролию 0 - ещё не решено, 1 - отказ, 2 - одобрен
    }

    struct reqestUp{ // заявка на повышение 
        address user;
        address shope; // где хочет работать 
        bool status; // status - статус расмотрения админом. По умолчанию false.
        uint approval; // approval - одобрение или откланение админом повышения ролию 0 - ещё не решено, 1 - отказ, 2 - одобрен
    }

    struct otziv{ // книга отзывов
        address creator;
        uint Ocenka;
        string comment;
        reactions[] React;
        answers[] Answers;
    }

    struct answers{ // комменатрии других пользователей
        address creator;
        string comment;
        reactions[] React;
    }

    struct reactions{
        address user;
        uint reaction; // 0 - лайк, 1 - дизлайк
    }

    struct shop{
        string name_shop;
        address address_shop;
        otziv[] Otziv; // книга отзывов
        address[] workers; // работники
    }

    users[] Users;
    shop[] Shop;
    reqestUp[] ReqestUp;
    reqestDown[] ReqestDown;

    constructor(){
        Users.push(users(0xDF80054F18b4535F2C56cd9BdED229f10d829E5a, 1, 1,keccak256(abi.encodePacked("1234")))); // admin
        Users.push(users(0x6801f0240E1fe1A2831e464e39e82E89e2911E34, 0, 0,keccak256(abi.encodePacked("1111")))); // users
        Users.push(users(0x4a89386fb7769c572b29Fb62818421c694bCb52F, 0, 0,keccak256(abi.encodePacked("1111"))));
    }

    // modifiers
    modifier isNotRegistered(address user){
        bool isReg = false;
        for(uint i = 0; i < Users.length; i++){
            if(Users[i].address_user == user){
                isReg = true;
            }
        }
        require(isReg, "101"); // error 101 - not registred
        _;
    }

    modifier isAdmin(address user){
        bool isAdm = false;
        for(uint i = 0; i < Users.length; i++){
            if(Users[i].address_user == user){
                if(Users[i].role == 1){
                    isAdm = true;
                }
            }
        }
        require(isAdm, "102"); // error 102 - not admin
        _;
    }

    modifier isRegistered(address user){
        for(uint i = 0; i < Users.length; i++){
            require(Users[i].address_user !=user, "103"); // error 103 - already registered user
        }
        _;
    }

    modifier shopIsExists(address newShop) {
        for (uint i = 0; i < Users.length; i++) {
            require(Users[i].address_user != newShop, "104"); // error 104 - shop is exists
        }
        _;
    }

    modifier shopIsNotExists(address shope) {
        for (uint i = 0; i < Shop.length; i++) {
            require(Shop[i].address_shop == shope, "105"); // error 105 - shop is not exists
        }
        _;
    }

    modifier isNotAdmin(address user){
        bool isNotAdm = false;
        for(uint i = 0; i < Users.length; i++){
            if(Users[i].address_user == user){
                if(Users[i].role != 1){
                    isNotAdm = true;
                }
            }
        }
        require(isNotAdm, "106"); // error 106 - already admin
        _;
    }

    modifier isBuyer(address user){
        bool isBuyr = false;
        for(uint i = 0; i < Users.length; i++){
            if(Users[i].address_user == user){
                if(Users[i].ActiveRole == 0){
                    isBuyr = true;
                }
            }
        }
        require(isBuyr, "107"); // error 107 - not buyer
        _;
    }

    // admins functions
    function roleChange(address user, uint role) public isAdmin(msg.sender){
        for(uint id = 0; id < Users.length; id++){
            require(Users[id].address_user == user, "301"); // error 301 - what the user?
            require(Users[id].role != role, "201"); // error 201 - already has this role
            Users[id].role = role;
            Users[id].ActiveRole = role;
        }
    }

    function addNewAdmin(address user) public isAdmin(msg.sender) isNotRegistered(user) isNotAdmin(user){
        for(uint id = 0; id < Users.length; id++){
            require(Users[id].address_user == user, "302"); // error 302 - what the user?
            Users[id].role = 1;
            Users[id].ActiveRole = 1;
        }
    }

    function regNewShop(address newShop) public shopIsExists(newShop) isAdmin(msg.sender){
        shop storage new_shop = Shop.push();
        new_shop.name_shop = "ddd";
        new_shop.address_shop = newShop;
    }

    function deleteShop(address shope) public isAdmin(msg.sender) shopIsNotExists(shope){
        for(uint id = 0; id < Shop.length; id++){
            require(Shop[id].address_shop == shope, "303"); // error 303 - what the shop?
            for(uint idW; idW < Shop[id].workers.length; idW++){
                for(uint idU = 0; idU < Users.length; idU++){
                    if(Users[idU].address_user == Shop[id].workers[idW]){
                        Users[idU].role = 0;
                        Users[idU].ActiveRole = 0;
                    }
                }
            }
            delete Shop[id];
        }
    }

    function checkReqestInSeller(uint idReqest, uint adminAnswer) public isAdmin(msg.sender){
        require(ReqestUp[idReqest].status != true, "208"); // error 208 - reqest has already been considered
        require(adminAnswer < 3, "209"); // error 209 - there is no such answer
        ReqestUp[idReqest].status = true;
        require(adminAnswer != 0, "210"); // error 210 - you need to reject or approve the application
        ReqestUp[idReqest].approval = adminAnswer;
    }

    function addNewSeller(uint idReqest) public isAdmin(msg.sender){
        require(ReqestUp[idReqest].status != false, "211"); // error 211 - reqest has not been considered
        if(ReqestUp[idReqest].approval == 2){
            for(uint id = 0; id < Users.length; id++){
                require(Users[id].address_user == ReqestUp[idReqest].user, "310"); // error 310 - what the user?
                Users[id].role = 2;
                Users[id].ActiveRole = 2;
                for(uint idS = 0; idS < Shop.length; idS++){
                    require(Shop[idS].address_shop == ReqestUp[idReqest].shope, "311"); // error 311 = what the shop?
                    Shop[idS].workers.push(ReqestUp[idReqest].user);
                }
            }
        }
    }
    
    function checkReqestDownSeller(uint idReqest, uint adminAnswer) public isAdmin(msg.sender){
        require(ReqestDown[idReqest].status != true, "208"); // error 208 - reqest has already been considered
        require(adminAnswer < 3, "209"); // error 209 - there is no such answer
        ReqestDown[idReqest].status = true;
        require(adminAnswer != 0, "210"); // error 210 - you need to reject or approve the application
        ReqestDown[idReqest].approval = adminAnswer;
    }

    function deleteSeller(uint idReqest) public isAdmin(msg.sender){
        require(ReqestDown[idReqest].status != false, "211"); // error 211 - reqest has not been considered
        if(ReqestDown[idReqest].approval == 2){
            for(uint id = 0; id < Users.length; id++){
                require(Users[id].address_user == ReqestDown[idReqest].user, "310"); // error 310 - what the user?
                Users[id].role = 0;
                Users[id].ActiveRole = 0;
                for(uint idS = 0; idS < Shop.length; idS++){
                    require(Shop[idS].address_shop == ReqestDown[idReqest].shope, "311"); // error 311 = what the shop?
                    for(uint idW = 0; idW < Shop[idS].workers.length; idW++){
                        require(Shop[idS].workers[idW] == ReqestDown[idReqest].user, "312"); // error 312 - what the user?
                        delete Shop[idS].workers[idW];
                    }
                }
            }
        }
    }

    // all functions
    function regNewUser(address newUser, uint role) public isRegistered(newUser){
        require(role < 3, "202"); // error 202 - incorrect role
        Users.push(users(newUser, role, role, keccak256(abi.encodePacked("1111"))));
    }

    function roleSwitch(address user) public isNotRegistered(msg.sender){
        for(uint id = 0; id < Users.length; id++){
            require(Users[id].address_user == user, "304"); // error 304 - what the user?
            require(Users[id].role != 0, "206"); // error 206 - already have role = 0(buyer)
            Users[id].ActiveRole = 0;
        }
    }

    function feedback(address shope, uint ocenka, string memory comm)public isBuyer(msg.sender) isNotRegistered(msg.sender){
        for(uint id = 0; id < Shop.length; id++){
            require(Shop[id].address_shop == shope, "305"); // error 305 - what the shop?
            for(uint idW = 0; idW < Shop[id].workers.length; idW++){
                require(msg.sender != Shop[id].workers[idW], "203"); // error 203 - a store employee cannot leave a review on his store
            }
            otziv storage newOtziv = Shop[id].Otziv.push();
            newOtziv.creator = msg.sender;
            newOtziv.Ocenka = ocenka;
            newOtziv.comment = comm;
            
        }
    }

    function addCommentForFeedback(address shope, uint idOtziv, string memory comm) public isNotRegistered(msg.sender){
        for(uint id = 0; id < Shop.length; id++){
            require(Shop[id].address_shop == shope, "306"); // error 306 - what the shop?
            answers storage newAnswer = Shop[id].Otziv[idOtziv].Answers.push();
            newAnswer.creator = msg.sender;
            newAnswer.comment = comm;
        }
    }

    function addReactionForOtziv(address shope, uint idOtziv, uint reacti) public isNotRegistered(msg.sender){
        require(reacti < 2, "204"); // error 204 - there is no such reaction in reaction for Otziv
        for(uint id = 0; id < Shop.length; id++){
            require(Shop[id].address_shop == shope, "307"); // error 307 - what the shop?
            reactions storage newReaction = Shop[id].Otziv[idOtziv].React.push();
            newReaction.user = msg.sender;
            newReaction.reaction = reacti;
        }
    }

    function addReactionForAnswer(address shope, uint idOtziv, uint idAnswer, uint reacti) public isNotRegistered(msg.sender){
        require(reacti < 2, "205"); // error 205 - there is no such reaction in reaction for Answer
        for(uint id = 0; id < Shop.length; id++){
            require(Shop[id].address_shop == shope, "308"); // error 308 - what the shop?
            reactions storage newReaction = Shop[id].Otziv[idOtziv].Answers[idAnswer].React.push();
            newReaction.user = msg.sender;
            newReaction.reaction = reacti;
        }
    }

    function addReqestInSeller(address shope) public isNotRegistered(msg.sender) shopIsNotExists(shope){
        for(uint id = 0; id < Users.length; id++){
            require(Users[id].address_user == msg.sender, "309"); // error 309 - what the user?
            require(Users[id].role != 2, "207"); // error 207 - you already have role seller
            ReqestUp.push(reqestUp(msg.sender, shope, false, 0));
        }
    }

    function addReqestDownSeller(address shope) public isNotRegistered(msg.sender) shopIsNotExists(shope){
        for(uint id = 0; id < Users.length; id++){
            require(Users[id].address_user == msg.sender, "309"); // error 309 - what the user?
            require(Users[id].role == 2, "212"); // error 212 - you dont already have role seller
            ReqestDown.push(reqestDown(msg.sender, shope, false, 0));
        }
    }
    
    // view functions
    function view_Shops() public view returns (shop[] memory) {
        return (Shop);
    }

    function view_Users() public view returns (users[] memory) {
        return (Users);
    }

    function view_ReqestsUp() public view returns (reqestUp[] memory) {
        return (ReqestUp);
    }

    function view_ReqestsDown() public view returns (reqestDown[] memory) {
        return (ReqestDown);
    }
}
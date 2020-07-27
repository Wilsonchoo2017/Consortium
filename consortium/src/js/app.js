App = {
  web3Provider: null,
  contracts: {},

  init: async function() {

    return await App.initWeb3();
  },

  initWeb3: async function() {
    // Modern dapp browsers...
    if (window.ethereum) {
      App.web3Provider = window.ethereum;
      try {
        // Request account access
        await window.ethereum.enable();
      } catch (error) {
        // User denied account access...
        console.error("User denied account access")
      }
    }
    // Legacy dapp browsers...
    else if (window.web3) {
      App.web3Provider = window.web3.currentProvider;
    }
    // If no injected web3 instance is detected, fall back to Ganache
    else {
      App.web3Provider = new Web3.providers.HttpProvider('http://localhost:7545');
    }
    web3 = new Web3(App.web3Provider);

    return App.initContract();
  },

  initContract: function() {
    // $.getJSON('Adoption.json', function(data) {
    //   // Get the necessary contract artifact file and instantiate it with truffle-contract
    //   var AdoptionArtifact = data;
    //   App.contracts.Adoption = TruffleContract(AdoptionArtifact);
    //
    //   // Set the provider for our contract
    //   App.contracts.Adoption.setProvider(App.web3Provider);
    //
    //   // Use our contract to retrieve and mark the adopted pets
    //   return App.markAdopted();
    // });

    $.getJSON('TenancyAgreementFactory.json', function(data) {
      // Get the necessary contract artifact file and instantiate it with truffle-contract
      var TenancyAgreementFactoryArtifact = data;
      App.contracts.TenancyAgreementFactory = TruffleContract(TenancyAgreementFactoryArtifact);

      // Set the provider for our contract
      App.contracts.TenancyAgreementFactory.setProvider(App.web3Provider);

      // Use our contract to retrieve and mark the adopted pets
      //return App.markAdopted();
    });

    return App.bindEvents();
  },

  bindEvents: function() {
    $(document).on('click', '#create-btn', App.handleContract);
    $(document).on('click', '#pay-btn', App.payRent);
    $(document).on('click', '#tenant-btn', App.showTenantForm);
    $(document).on('click', '.owner', App.showOwnerForm);
  },

  // handle create new lease contract
  handleContract: function(event) {
    event.preventDefault();
    console.log('handling');
    var tenancyInstance;

    web3.eth.getAccounts(function(error, accounts) {
      if (error) {
        console.log(error);
      }

      var account = accounts[0];

      App.contracts.TenancyAgreementFactory.deployed().then(function(instance) {
        tenancyInstance = instance;
        var rent = parseInt($('#rent').val());
        var duration = parseInt($('#duration').val());
        var bond = parseInt($('#bond').val());
        var periodic = false;
        if ($("#periodic :selected").val() == "yes"){
          periodic = true;
        }
        var hd = false;
        if ($("#holding-deposit :selected").val() == "yes"){
          hd = true;
        }
        return tenancyInstance.proposeLeaseAsManager(account, rent,periodic, duration, hd, bond, {from: account});
      }).then(function(result) {
        alert('create lease contract success');
      }).catch(function(err) {
        console.log('handle fail');
        console.log(err.message);
      });
    });
  },

  showTenantForm: function(event) {
      $("#tenant-form").show();
  },

  showOwnerForm: function(event) {
      $("#owner-form").show();
  },
  // handle negotiation
  negotiate: function(event) {
    event.preventDefault();
    console.log('paying');
    var tenancyInstance;

    web3.eth.getAccounts(function(error, accounts) {
      if (error) {
        console.log(error);
      }

      var account = accounts[0];

      App.contracts.TenancyAgreementFactory.deployed().then(function(instance) {
        tenancyInstance = instance;
        var rentTenant = parseInt($('#rent-tenant').val());
        var rentPrice = parseInt($('#rent-price').val());
        console.log(account);
        if ($("#periodic :selected").val() == "yes"){
          periodic = true;
        }
        return tenancyInstance.negotiatePriceTenant(rentPrice, {from: account});
      }).then(function(result) {
        alert('pay rent success');
      }).catch(function(err) {
        console.log('pay rent fail');
        console.log(err.message);
      });
    });
  },

  // handle pay rent
  payRent: function(event) {
    event.preventDefault();
    console.log('paying');
    var tenancyInstance;

    web3.eth.getAccounts(function(error, accounts) {
      if (error) {
        console.log(error);
      }

      var account = accounts[0];

      App.contracts.TenancyAgreementFactory.deployed().then(function(instance) {
        tenancyInstance = instance;
        var rentTenant = parseInt($('#rent-tenant').val());
        var rentPrice = parseInt($('#rent-price').val());
        console.log(account);
        return tenancyInstance.payRent(rentPrice, {from: account});
      }).then(function(result) {
        alert('pay rent success');
      }).catch(function(err) {
        console.log('pay rent fail');
        console.log(err.message);
      });
    });
  },

  // handle pay rent
  signLease: function(event) {
    event.preventDefault();
    var tenancyInstance;
    web3.eth.getAccounts(function(error, accounts) {
      if (error) {
        console.log(error);
      }
      var account = accounts[0];

      App.contracts.TenancyAgreementFactory.deployed().then(function(instance) {
        tenancyInstance = instance;
        return tenancyInstance.acceptLease( {from: account});
      }).then(function(result) {
        alert('lease signed!');
      }).catch(function(err) {
        console.log('sign lease fail');
        console.log(err.message);
      });
    });
  }
};

!(function($) {
  "use strict";

  // Preloader
  $(window).on('load', function() {
    if ($('#preloader').length) {
      $('#preloader').delay(100).fadeOut('slow', function() {
        $(this).remove();
      });
    }
    console.log('load 2');
    App.init();
  });

  // Smooth scroll for the navigation menu and links with .scrollto classes
  var scrolltoOffset = $('#header').outerHeight() - 1;
  $(document).on('click', '.nav-menu a, .mobile-nav a, .scrollto', function(e) {
    if (location.pathname.replace(/^\//, '') == this.pathname.replace(/^\//, '') && location.hostname == this.hostname) {
      var target = $(this.hash);
      if (target.length) {
        e.preventDefault();

        var scrollto = target.offset().top - scrolltoOffset;

        if ($(this).attr("href") == '#header') {
          scrollto = 0;
        }

        $('html, body').animate({
          scrollTop: scrollto
        }, 1500, 'easeInOutExpo');

        if ($(this).parents('.nav-menu, .mobile-nav').length) {
          $('.nav-menu .active, .mobile-nav .active').removeClass('active');
          $(this).closest('li').addClass('active');
        }

        if ($('body').hasClass('mobile-nav-active')) {
          $('body').removeClass('mobile-nav-active');
          $('.mobile-nav-toggle i').toggleClass('icofont-navigation-menu icofont-close');
          $('.mobile-nav-overly').fadeOut();
        }
        return false;
      }
    }
  });

  // Activate smooth scroll on page load with hash links in the url
  $(document).ready(function() {
    if (window.location.hash) {
      var initial_nav = window.location.hash;
      if ($(initial_nav).length) {
        var scrollto = $(initial_nav).offset().top - scrolltoOffset;
        $('html, body').animate({
          scrollTop: scrollto
        }, 1500, 'easeInOutExpo');
      }
    }


  });


  // Navigation active state on scroll
  var nav_sections = $('section');
  var main_nav = $('.nav-menu, #mobile-nav');

  $(window).on('scroll', function() {
    var cur_pos = $(this).scrollTop() + 200;

    nav_sections.each(function() {
      var top = $(this).offset().top,
        bottom = top + $(this).outerHeight();

      if (cur_pos >= top && cur_pos <= bottom) {
        if (cur_pos <= bottom) {
          main_nav.find('li').removeClass('active');
        }
        main_nav.find('a[href="#' + $(this).attr('id') + '"]').parent('li').addClass('active');
      }
      if (cur_pos < 300) {
        $(".nav-menu ul:first li:first").addClass('active');
      }
    });
  });

  // Back to top button
  $(window).scroll(function() {
    if ($(this).scrollTop() > 100) {
      $('.back-to-top').fadeIn('slow');
    } else {
      $('.back-to-top').fadeOut('slow');
    }
  });

  $('.back-to-top').click(function() {
    $('html, body').animate({
      scrollTop: 0
    }, 1500, 'easeInOutExpo');
    return false;
  });

  // Init AOS
  function aos_init() {
    AOS.init({
      duration: 1000,
      once: true
    });
  }
  $(window).on('load', function() {
    aos_init();
  });

})(jQuery);

import Foundation
@testable import KsApi
@testable import Library
import Prelude
import ReactiveExtensions
import ReactiveExtensions_TestHelpers
import ReactiveSwift
import XCTest

final class RewardCardViewModelTests: TestCase {
  fileprivate let vm: RewardCardViewModelType = RewardCardViewModel()

  private let cardUserInteractionIsEnabled = TestObserver<Bool, Never>()
  private let conversionLabelHidden = TestObserver<Bool, Never>()
  private let conversionLabelText = TestObserver<String, Never>()
  private let descriptionLabelText = TestObserver<String, Never>()
  private let includedItemsStackViewHidden = TestObserver<Bool, Never>()
  private let items = TestObserver<[String], Never>()
  private let pillCollectionViewHidden = TestObserver<Bool, Never>()
  private let reloadPills = TestObserver<[String], Never>()
  private let rewardMinimumLabelText = TestObserver<String, Never>()
  private let rewardSelected = TestObserver<Int, Never>()
  private let rewardTitleLabelHidden = TestObserver<Bool, Never>()
  private let rewardTitleLabelText = TestObserver<String, Never>()
  private let stateIconImageName = TestObserver<String, Never>()
  private let stateIconImageTintColor = TestObserver<UIColor, Never>()
  private let stateIconImageViewContainerBackgroundColor = TestObserver<UIColor, Never>()
  private let stateIconImageViewContainerHidden = TestObserver<Bool, Never>()

  override func setUp() {
    super.setUp()

    self.vm.outputs.cardUserInteractionIsEnabled.observe(self.cardUserInteractionIsEnabled.observer)
    self.vm.outputs.conversionLabelHidden.observe(self.conversionLabelHidden.observer)
    self.vm.outputs.conversionLabelText.observe(self.conversionLabelText.observer)
    self.vm.outputs.descriptionLabelText.observe(self.descriptionLabelText.observer)
    self.vm.outputs.includedItemsStackViewHidden.observe(self.includedItemsStackViewHidden.observer)
    self.vm.outputs.items.observe(self.items.observer)
    self.vm.outputs.pillCollectionViewHidden.observe(self.pillCollectionViewHidden.observer)
    self.vm.outputs.reloadPills.observe(self.reloadPills.observer)
    self.vm.outputs.rewardMinimumLabelText.observe(self.rewardMinimumLabelText.observer)
    self.vm.outputs.rewardSelected.observe(self.rewardSelected.observer)
    self.vm.outputs.rewardTitleLabelHidden.observe(self.rewardTitleLabelHidden.observer)
    self.vm.outputs.rewardTitleLabelText.observe(self.rewardTitleLabelText.observer)
    self.vm.outputs.stateIconImageName.observe(self.stateIconImageName.observer)
    self.vm.outputs.stateIconImageTintColor.observe(self.stateIconImageTintColor.observer)
    self.vm.outputs.stateIconImageViewContainerBackgroundColor
      .observe(self.stateIconImageViewContainerBackgroundColor.observer)
    self.vm.outputs.stateIconImageViewContainerHidden.observe(self.stateIconImageViewContainerHidden.observer)
  }

  // MARK: - Reward Title

  func testTitleLabel() {
    let reward = .template
      |> Reward.lens.title .~ "The thing"
      |> Reward.lens.remaining .~ nil

    self.vm.inputs.configureWith(
      project: .template,
      rewardOrBacking: .left(reward)
    )

    self.rewardTitleLabelHidden.assertValues([false])
    self.rewardTitleLabelText.assertValues(["The thing"])
  }

  func testTitleLabel_NoTitle() {
    let reward = .template
      |> Reward.lens.title .~ nil
      |> Reward.lens.remaining .~ nil

    self.vm.inputs.configureWith(
      project: .template,
      rewardOrBacking: .left(reward)
    )

    self.rewardTitleLabelHidden.assertValues([true])
    self.rewardTitleLabelText.assertValues([""])
  }

  func testTitleLabel_NoTitle_NoReward() {
    let reward = Reward.noReward

    self.vm.inputs.configureWith(
      project: .template,
      rewardOrBacking: .left(reward)
    )

    self.rewardTitleLabelHidden.assertValues([false])
    self.rewardTitleLabelText.assertValues(["Make a pledge without a reward"])
  }

  func testTitleLabel_BackedNoReward() {
    let reward = Reward.noReward

    let project = Project.cosmicSurgery
      |> Project.lens.state .~ .live
      |> Project.lens.personalization.isBacking .~ true
      |> Project.lens.personalization.backing .~ (
        .template
          |> Backing.lens.reward .~ reward
          |> Backing.lens.rewardId .~ reward.id
          |> Backing.lens.amount .~ 700
      )

    self.vm.inputs.configureWith(
      project: project,
      rewardOrBacking: .left(reward)
    )

    self.rewardTitleLabelHidden.assertValues([false])
    self.rewardTitleLabelText.assertValues([
      "Thank you for supporting this project."
    ])
  }

  // MARK: - Reward Minimum

  func testMinimumLabel_US_Project_US_UserLocation() {
    let project = Project.template
      |> Project.lens.country .~ .us
    let reward = .template |> Reward.lens.minimum .~ 1_000

    withEnvironment(countryCode: "US") {
      self.vm.inputs.configureWith(project: project, rewardOrBacking: .left(reward))

      self.rewardMinimumLabelText.assertValues(
        ["$1,000"],
        "Reward minimum appears in project's currency, without a currency symbol."
      )
    }
  }

  func testMinimumLabel_US_Project_NonUS_UserLocation() {
    let project = Project.template
      |> Project.lens.country .~ .us
    let reward = .template |> Reward.lens.minimum .~ 1_000

    withEnvironment(countryCode: "MX") {
      self.vm.inputs.configureWith(project: project, rewardOrBacking: .left(reward))

      self.rewardMinimumLabelText.assertValues(
        ["US$ 1,000"],
        "Reward minimum appears in project's currency, with a currency symbol."
      )
    }
  }

  func testMinimumLabel_NonUS_Project_US_User_Currency_US_UserLocation() {
    let project = Project.template
      |> Project.lens.country .~ .gb
      |> Project.lens.stats.currency .~ Project.Country.gb.currencyCode
      |> Project.lens.stats.currentCurrency .~ Project.Country.us.currencyCode
      |> Project.lens.stats.currentCurrencyRate .~ 0.5
    let reward = .template |> Reward.lens.minimum .~ 1_000

    withEnvironment(countryCode: "US") {
      self.vm.inputs.configureWith(project: project, rewardOrBacking: .left(reward))

      self.rewardMinimumLabelText.assertValues(
        ["£1,000"],
        "Reward minimum always appears in the project's currency."
      )
    }
  }

  func testMinimumLabel_NonUs_Project_US_UserCurrency_NonUS_UserLocation() {
    let project = Project.template
      |> Project.lens.country .~ .gb
      |> Project.lens.stats.currency .~ Project.Country.gb.currencyCode
      |> Project.lens.stats.currentCurrency .~ Project.Country.us.currencyCode
      |> Project.lens.stats.currentCurrencyRate .~ 0.5
    let reward = .template |> Reward.lens.minimum .~ 1_000

    withEnvironment(countryCode: "MX") {
      self.vm.inputs.configureWith(project: project, rewardOrBacking: .left(reward))

      self.rewardMinimumLabelText.assertValues(
        ["£1,000"],
        "Reward minimum always appears in the project's currency."
      )
    }
  }

  func testMinimumLabel_NoReward_US_Project_US_UserLocation() {
    let project = Project.template
      |> Project.lens.country .~ .us
    let reward = Reward.noReward

    withEnvironment(countryCode: "US") {
      self.vm.inputs.configureWith(project: project, rewardOrBacking: .left(reward))

      self.rewardMinimumLabelText.assertValues(
        ["$1"],
        "No-reward min appears in the project's currency without a currency symbol"
      )
    }
  }

  func testMinimumLabel_NoReward_US_Project_NonUS_UserLocation() {
    let project = Project.template
      |> Project.lens.country .~ .us
    let reward = Reward.noReward

    withEnvironment(countryCode: "MX") {
      self.vm.inputs.configureWith(project: project, rewardOrBacking: .left(reward))

      self.rewardMinimumLabelText.assertValues(
        ["US$ 1"],
        "No-reward min appears in the project's currency with a currency symbol"
      )
    }
  }

  func testMinimumLabel_NoReward_NonUS_Project_US_UserLocation() {
    let project = Project.template
      |> Project.lens.country .~ Project.Country.mx
    let reward = Reward.noReward

    withEnvironment(countryCode: "US") {
      self.vm.inputs.configureWith(project: project, rewardOrBacking: .left(reward))

      self.rewardMinimumLabelText.assertValues(
        ["MX$ 10"],
        """
        No-reward min always appears in the project's currency,
        with the amount depending on the project's country
        """
      )
    }
  }

  func testMinimumLabel_NoReward_NonUS_Project_NonUS_UserLocation() {
    let project = Project.template
      |> Project.lens.country .~ Project.Country.mx
    let reward = Reward.noReward

    withEnvironment(countryCode: "CA") {
      self.vm.inputs.configureWith(project: project, rewardOrBacking: .left(reward))

      self.rewardMinimumLabelText.assertValues(
        ["MX$ 10"],
        """
        No-reward min always appears in the project's currency,
        with the amount depending on the project's country
        """
      )
    }
  }

  // MARK: - Included Items

  func testItems() {
    let reward = .template
      |> Reward.lens.rewardsItems .~ [
        .template
          |> RewardsItem.lens.item .~ (
            .template
              |> Item.lens.name .~ "The thing"
          ),
        .template
          |> RewardsItem.lens.quantity .~ 1_000
          |> RewardsItem.lens.item .~ (
            .template
              |> Item.lens.name .~ "The other thing"
          )
      ]

    self.vm.inputs.configureWith(project: .template, rewardOrBacking: .left(reward))

    self.items.assertValues([["The thing", "(1,000) The other thing"]])
    self.includedItemsStackViewHidden.assertValues([false])
  }

  func testItemsContainerHidden_WithNoItems() {
    self.vm.inputs.configureWith(
      project: .template,
      rewardOrBacking: .left(.template |> Reward.lens.rewardsItems .~ [])
    )

    self.includedItemsStackViewHidden.assertValues([true])
  }

  // MARK: Description Label

  func testDescriptionLabel() {
    let project = Project.template
    let reward = Reward.template

    self.vm.inputs.configureWith(project: project, rewardOrBacking: .left(reward))

    self.descriptionLabelText.assertValues([reward.description])
  }

  func testDescriptionLabel_NoReward() {
    let project = Project.template
    let reward = Reward.noReward

    self.vm.inputs.configureWith(project: project, rewardOrBacking: .left(reward))

    self.descriptionLabelText.assertValues(["Pledge any amount to help bring this project to life."])
  }

  // MARK: - Conversion Label

  func testConversionLabel_US_UserCurrency_US_Location_US_Project_ConfiguredWithReward() {
    let project = .template
      |> Project.lens.country .~ .us
      |> Project.lens.stats.currency .~ "USD"
      |> Project.lens.stats.currentCurrency .~ "USD"
    let reward = .template |> Reward.lens.minimum .~ 1_000

    withEnvironment(countryCode: "US") {
      self.vm.inputs.configureWith(project: project, rewardOrBacking: .left(reward))

      self.conversionLabelHidden.assertValues(
        [true],
        "US user with US currency preferences, viewing US project does not see conversion."
      )
      self.conversionLabelText.assertValueCount(0)
    }
  }

  func testConversionLabel_US_UserCurrency_US_Location_US_Project_ConfiguredWithBacking() {
    let project = .template
      |> Project.lens.country .~ .us
      |> Project.lens.stats.currency .~ "USD"
      |> Project.lens.stats.currentCurrency .~ "USD"
    let reward = .template |> Reward.lens.minimum .~ 30
    let backing = .template
      |> Backing.lens.amount .~ 42
      |> Backing.lens.reward .~ reward

    withEnvironment(countryCode: "US") {
      self.vm.inputs.configureWith(project: project, rewardOrBacking: .right(backing))

      self.conversionLabelHidden.assertValues(
        [true],
        "US user with US currency preferences, viewing US project does not see conversion."
      )
      self.conversionLabelText.assertValueCount(0)
    }
  }

  func testConversionLabel_US_UserCurrency_US_Location_NonUS_Project_ConfiguredWithReward() {
    let project = .template
      |> Project.lens.country .~ .ca
      |> Project.lens.stats.currency .~ Project.Country.ca.currencyCode
      |> Project.lens.stats.currentCurrency .~ Project.Country.us.currencyCode
      |> Project.lens.stats.currentCurrencyRate .~ 2.0
    let reward = .template |> Reward.lens.minimum .~ 1

    withEnvironment(countryCode: "US") {
      self.vm.inputs.configureWith(project: project, rewardOrBacking: .left(reward))

      self.conversionLabelHidden.assertValues(
        [false],
        """
        US user with US currency preferences, viewing non-US project
        sees conversion.
        """
      )
      self.conversionLabelText.assertValues(["About $2"], "Conversion without a currency symbol")
    }
  }

  func testConversionLabel_US_UserCurrency_US_Location_NonUS_Project_ConfiguredWithBacking() {
    let project = .template
      |> Project.lens.country .~ .ca
      |> Project.lens.stats.currency .~ Project.Country.ca.currencyCode
      |> Project.lens.stats.currentCurrency .~ Project.Country.us.currencyCode
      |> Project.lens.stats.currentCurrencyRate .~ 2.0
    let reward = .template |> Reward.lens.minimum .~ 30
    let backing = .template
      |> Backing.lens.amount .~ 42
      |> Backing.lens.reward .~ reward

    withEnvironment(countryCode: "US") {
      self.vm.inputs.configureWith(project: project, rewardOrBacking: .right(backing))

      self.conversionLabelHidden.assertValues(
        [false],
        """
        US user with US currency preferences, viewing non-US project
        sees conversion.
        """
      )
      self.conversionLabelText.assertValues(["About $84"], "Conversion label rounds up.")
    }
  }

  func testConversionLabel_US_Currency_NonUS_Location_NonUS_Project_ConfiguredWithReward() {
    let project = .template
      |> Project.lens.country .~ .ca
      |> Project.lens.stats.currency .~ Project.Country.ca.currencyCode
      |> Project.lens.stats.currentCurrency .~ Project.Country.us.currencyCode
      |> Project.lens.stats.currentCurrencyRate .~ 2.0
    let reward = .template |> Reward.lens.minimum .~ 1

    withEnvironment(countryCode: "MX") {
      self.vm.inputs.configureWith(project: project, rewardOrBacking: .left(reward))

      self.conversionLabelHidden.assertValues(
        [false],
        """
        User with US currency preferences, non-US location, viewing non-US project
        sees conversion.
        """
      )
      self.conversionLabelText.assertValues(["About US$ 2"], "Conversion label shows US symbol.")
    }
  }

  func testConversionLabel_US_Currency_NonUS_Location_NonUS_Project_ConfiguredWithBacking() {
    let project = .template
      |> Project.lens.country .~ .ca
      |> Project.lens.stats.currency .~ Project.Country.ca.currencyCode
      |> Project.lens.stats.staticUsdRate .~ 0.76
      |> Project.lens.stats.currentCurrency .~ Project.Country.us.currencyCode
      |> Project.lens.stats.currentCurrencyRate .~ 2.0
    let reward = .template |> Reward.lens.minimum .~ 1
    let backing = .template
      |> Backing.lens.amount .~ 2
      |> Backing.lens.reward .~ reward

    withEnvironment(countryCode: "MX") {
      self.vm.inputs.configureWith(project: project, rewardOrBacking: .right(backing))

      self.conversionLabelHidden.assertValues(
        [false],
        "US User currency in non-US location viewing non-US project sees conversion."
      )
      self.conversionLabelText.assertValues(["About US$ 4"], "Conversion label shows US symbol.")
    }
  }

  func testConversionLabel_Unknown_Location_US_Project_ConfiguredWithReward_WithoutUserCurrency() {
    let project = .template
      |> Project.lens.country .~ .us
      |> Project.lens.stats.currency .~ Project.Country.us.currencyCode
      |> Project.lens.stats.currentCurrency .~ nil
      |> Project.lens.stats.currentCurrencyRate .~ nil
    let reward = .template |> Reward.lens.minimum .~ 1

    withEnvironment(countryCode: "XX") {
      self.vm.inputs.configureWith(project: project, rewardOrBacking: .left(reward))

      self.conversionLabelHidden.assertValues(
        [true],
        "Unknown-location, unknown-currency user viewing US project does not see conversion."
      )
    }
  }

  func testConversionLabel_Unknown_Location_US_Project_ConfiguredWithBacking_WithoutUserCurrency() {
    let project = .template
      |> Project.lens.country .~ .us
      |> Project.lens.stats.currency .~ Project.Country.us.currencyCode
      |> Project.lens.stats.currentCurrency .~ nil
      |> Project.lens.stats.currentCurrencyRate .~ nil
    let reward = .template |> Reward.lens.minimum .~ 1
    let backing = .template
      |> Backing.lens.amount .~ 2
      |> Backing.lens.reward .~ reward

    withEnvironment(countryCode: "XX") {
      self.vm.inputs.configureWith(project: project, rewardOrBacking: .right(backing))

      self.conversionLabelHidden.assertValues(
        [true],
        "Unknown-location, unknown-currency user viewing US project does not see conversion."
      )
    }
  }

  func testConversionLabel_Unknown_Location_NonUS_Project_ConfiguredWithReward_WithoutUserCurrency() {
    let project = .template
      |> Project.lens.country .~ .ca
      |> Project.lens.stats.currency .~ Project.Country.ca.currencyCode
      |> Project.lens.stats.staticUsdRate .~ 0.76
      |> Project.lens.stats.currentCurrency .~ nil
      |> Project.lens.stats.currentCurrencyRate .~ nil
    let reward = .template |> Reward.lens.minimum .~ 1

    withEnvironment(countryCode: "XX") {
      self.vm.inputs.configureWith(project: project, rewardOrBacking: .left(reward))

      self.conversionLabelHidden.assertValues(
        [false],
        "Unknown-location, unknown-currency user viewing non-US project sees conversion to USD."
      )
      self.conversionLabelText.assertValues(["About US$ 1"], "Conversion label rounds up.")
    }
  }

  func testConversionLabel_Unknown_Location_NonUS_Project_ConfiguredWithBacking_WithoutUserCurrency() {
    let project = .template
      |> Project.lens.country .~ .ca
      |> Project.lens.stats.currency .~ Project.Country.ca.currencyCode
      |> Project.lens.stats.staticUsdRate .~ 0.76
      |> Project.lens.stats.currentCurrency .~ nil
      |> Project.lens.stats.currentCurrencyRate .~ nil
    let reward = .template |> Reward.lens.minimum .~ 1
    let backing = .template
      |> Backing.lens.amount .~ 2
      |> Backing.lens.reward .~ reward

    withEnvironment(countryCode: "XX") {
      self.vm.inputs.configureWith(project: project, rewardOrBacking: .right(backing))

      self.conversionLabelHidden.assertValues(
        [false],
        "Unknown-location, unknown-currency user viewing non-US project sees conversion to USD."
      )
      self.conversionLabelText.assertValues(["About US$ 2"], "Conversion label rounds up.")
    }
  }

  func testConversionLabel_NonUS_Location_NonUS_Locale_US_Project_ConfiguredWithReward() {
    let project = .template
      |> Project.lens.country .~ .us
      |> Project.lens.stats.currency .~ Project.Country.us.currencyCode
      |> Project.lens.stats.currentCurrency .~ Project.Country.mx.currencyCode
      |> Project.lens.stats.currentCurrencyRate .~ 2.0
    let reward = .template |> Reward.lens.minimum .~ 1

    withEnvironment(
      apiService: MockService(currency: "MXN"), countryCode: "MX"
    ) {
      self.vm.inputs.configureWith(project: project, rewardOrBacking: .left(reward))

      self.conversionLabelHidden.assertValues(
        [false],
        "Mexican user viewing US project sees conversion."
      )
      self.conversionLabelText.assertValues(["About MX$ 2"], "Conversion label rounds up.")
    }
  }

  func testConversionLabel_NonUS_Location_NonUS_Locale_US_Project_ConfiguredWithBacking() {
    let project = .template
      |> Project.lens.country .~ .us
      |> Project.lens.stats.currency .~ Project.Country.us.currencyCode
      |> Project.lens.stats.currentCurrency .~ Project.Country.mx.currencyCode
      |> Project.lens.stats.currentCurrencyRate .~ 2.0
    let reward = .template |> Reward.lens.minimum .~ 1
    let backing = .template
      |> Backing.lens.amount .~ 2
      |> Backing.lens.reward .~ reward

    withEnvironment(apiService: MockService(currency: "MXN"), countryCode: "MX") {
      self.vm.inputs.configureWith(project: project, rewardOrBacking: .right(backing))

      self.conversionLabelHidden.assertValues(
        [false],
        "Mexican user viewing US project sees conversion."
      )
      self.conversionLabelText.assertValues(["About MX$ 4"], "Conversion label rounds up.")
    }
  }

  func testConversionLabel_NonUS_Location_US_UserCurrency_US_Project_ConfiguredWithReward() {
    let project = .template
      |> Project.lens.country .~ .us
      |> Project.lens.stats.currency .~ Project.Country.us.currencyCode
      |> Project.lens.stats.currentCurrency .~ Project.Country.us.currencyCode
      |> Project.lens.stats.currentCurrencyRate .~ 1.0
    let reward = .template |> Reward.lens.minimum .~ 1_000

    withEnvironment(countryCode: "GB") {
      self.vm.inputs.configureWith(project: project, rewardOrBacking: .left(reward))

      self.conversionLabelHidden.assertValues(
        [true],
        "Non-US user location with USD user preferences viewing US project does not see conversion."
      )
      self.conversionLabelText.assertValueCount(0)
    }
  }

  func testConversionLabel_NonUS_Location_US_UserCurrency_US_Project_ConfiguredWithBacking() {
    let project = .template
      |> Project.lens.country .~ .us
      |> Project.lens.stats.currency .~ Project.Country.us.currencyCode
      |> Project.lens.stats.currentCurrency .~ Project.Country.us.currencyCode
      |> Project.lens.stats.currentCurrencyRate .~ 1.0
    let reward = .template |> Reward.lens.minimum .~ 1_000
    let backing = .template
      |> Backing.lens.amount .~ 2_000
      |> Backing.lens.reward .~ reward

    withEnvironment(countryCode: "GB") {
      self.vm.inputs.configureWith(project: project, rewardOrBacking: .right(backing))

      self.conversionLabelHidden.assertValues(
        [true],
        "Non-US user location with USD user preferences viewing US project does not see conversion."
      )
      self.conversionLabelText.assertValueCount(0)
    }
  }

  // MARK: - Card View

  func testRewardCardTapped() {
    self.vm.inputs.configureWith(project: .template, rewardOrBacking: .left(.template))

    self.vm.inputs.rewardCardTapped()

    self.rewardSelected.assertValues([Reward.template.id])
  }

  func testCardUserInteractionIsEnabled_NotLimitedReward() {
    let project = Project.template
    let reward = Reward.template
      |> Reward.lens.remaining .~ nil
      |> Reward.lens.minimum .~ 1_000

    self.vm.inputs.configureWith(project: project, rewardOrBacking: .left(reward))

    self.cardUserInteractionIsEnabled.assertValues([true])
  }

  func testCardUserInteractionIsEnabled_NotAllGone() {
    let project = Project.template
    let reward = Reward.template
      |> Reward.lens.remaining .~ 10
      |> Reward.lens.minimum .~ 1_000

    self.vm.inputs.configureWith(project: project, rewardOrBacking: .left(reward))

    self.cardUserInteractionIsEnabled.assertValues([true])
  }

  func testCardUserInteractionIsEnabled_AllGone() {
    let project = Project.template
    let reward = Reward.template
      |> Reward.lens.remaining .~ 0
      |> Reward.lens.minimum .~ 1_000

    self.vm.inputs.configureWith(project: project, rewardOrBacking: .left(reward))

    self.cardUserInteractionIsEnabled.assertValues([false])
  }

  // MARK: - Pills

  func testPillsLimitedReward() {
    self.pillCollectionViewHidden.assertValueCount(0)
    self.reloadPills.assertValueCount(0)

    let reward = Reward.postcards
      |> Reward.lens.limit .~ 100
      |> Reward.lens.remaining .~ 25

    self.vm.inputs.configureWith(project: .template, rewardOrBacking: .left(reward))

    self.pillCollectionViewHidden.assertValues([false])
    self.reloadPills.assertValues([
      ["25 left"]
    ])
  }

  func testPillsTimebasedReward_24hrs() {
    self.pillCollectionViewHidden.assertValueCount(0)
    self.reloadPills.assertValueCount(0)

    let reward = Reward.postcards
      |> Reward.lens.limit .~ nil
      |> Reward.lens.remaining .~ nil
      |> Reward.lens.endsAt .~ (MockDate().timeIntervalSince1970 + 60.0 * 60.0 * 24.0)

    self.vm.inputs.configureWith(project: .template, rewardOrBacking: .left(reward))

    self.pillCollectionViewHidden.assertValues([false])
    self.reloadPills.assertValues([
      ["24 hrs left"]
    ])
  }

  func testPillsTimebasedReward_4days() {
    self.pillCollectionViewHidden.assertValueCount(0)
    self.reloadPills.assertValueCount(0)

    let date = AppEnvironment.current.calendar.date(byAdding: DateComponents(day: 4), to: MockDate().date)

    let reward = Reward.postcards
      |> Reward.lens.limit .~ nil
      |> Reward.lens.remaining .~ nil
      |> Reward.lens.endsAt .~ date?.timeIntervalSince1970

    self.vm.inputs.configureWith(project: .template, rewardOrBacking: .left(reward))

    self.pillCollectionViewHidden.assertValues([false])
    self.reloadPills.assertValues([
      ["4 days left"]
    ])
  }

  func testPillsTimebasedAndLimitedReward() {
    self.pillCollectionViewHidden.assertValueCount(0)
    self.reloadPills.assertValueCount(0)

    let date = AppEnvironment.current.calendar.date(byAdding: DateComponents(day: 4), to: MockDate().date)

    let reward = Reward.postcards
      |> Reward.lens.limit .~ 100
      |> Reward.lens.remaining .~ 75
      |> Reward.lens.endsAt .~ date?.timeIntervalSince1970

    self.vm.inputs.configureWith(project: .template, rewardOrBacking: .left(reward))

    self.pillCollectionViewHidden.assertValues([false])
    self.reloadPills.assertValues([
      ["4 days left", "75 left"]
    ])
  }

  func testPillsTimebasedAndLimitedReward_ShippingEnabled() {
    self.pillCollectionViewHidden.assertValueCount(0)
    self.reloadPills.assertValueCount(0)

    let date = AppEnvironment.current.calendar.date(byAdding: DateComponents(day: 4), to: MockDate().date)

    let reward = Reward.postcards
      |> Reward.lens.limit .~ 100
      |> Reward.lens.remaining .~ 75
      |> Reward.lens.endsAt .~ date?.timeIntervalSince1970
      |> Reward.lens.shipping .~ (
        .template
          |> Reward.Shipping.lens.enabled .~ true
          |> Reward.Shipping.lens.preference .~ .restricted
          |> Reward.Shipping.lens.summary .~ "Anywhere in the world"
      )

    self.vm.inputs.configureWith(project: .template, rewardOrBacking: .left(reward))

    self.pillCollectionViewHidden.assertValues([false])
    self.reloadPills.assertValues([
      ["4 days left", "75 left", "Anywhere in the world"]
    ])
  }

  func testPillsTimebasedAndLimitedReward_ShippingEnabled_NonLive() {
    self.pillCollectionViewHidden.assertValueCount(0)
    self.reloadPills.assertValueCount(0)

    let date = AppEnvironment.current.calendar.date(byAdding: DateComponents(day: 4), to: MockDate().date)

    let project = .template
      |> Project.lens.state .~ .successful

    let reward = Reward.postcards
      |> Reward.lens.limit .~ 100
      |> Reward.lens.remaining .~ 75
      |> Reward.lens.endsAt .~ date?.timeIntervalSince1970
      |> Reward.lens.shipping .~ (
        .template
          |> Reward.Shipping.lens.enabled .~ true
          |> Reward.Shipping.lens.preference .~ .restricted
          |> Reward.Shipping.lens.summary .~ "Anywhere in the world"
      )

    self.vm.inputs.configureWith(project: project, rewardOrBacking: .left(reward))

    self.pillCollectionViewHidden.assertValues([true])
    self.reloadPills.assertValues([[]])
  }

  func testPillsTimebasedAndLimitedReward_NonLiveProject() {
    self.pillCollectionViewHidden.assertValueCount(0)
    self.reloadPills.assertValueCount(0)

    let date = AppEnvironment.current.calendar.date(byAdding: DateComponents(day: 4), to: MockDate().date)

    let project = Project.template
      |> Project.lens.state .~ .successful

    let reward = Reward.postcards
      |> Reward.lens.limit .~ 100
      |> Reward.lens.remaining .~ 75
      |> Reward.lens.endsAt .~ date?.timeIntervalSince1970

    self.vm.inputs.configureWith(project: project, rewardOrBacking: .left(reward))

    self.pillCollectionViewHidden.assertValues([true])
    self.reloadPills.assertValues([[]])
  }

  func testPillsTimebasedAndLimitedReward_Unavailable() {
    self.pillCollectionViewHidden.assertValueCount(0)
    self.reloadPills.assertValueCount(0)

    let reward = Reward.postcards
      |> Reward.lens.limit .~ 100
      |> Reward.lens.remaining .~ 0
      |> Reward.lens.endsAt .~ (MockDate().date.timeIntervalSince1970 - 1)

    self.vm.inputs.configureWith(project: .template, rewardOrBacking: .left(reward))

    self.pillCollectionViewHidden.assertValues([false])
    self.reloadPills.assertValues([["0 left"]])
  }

  func testPillsNonLimitedReward() {
    self.pillCollectionViewHidden.assertValueCount(0)
    self.reloadPills.assertValueCount(0)

    let reward = Reward.postcards
      |> Reward.lens.limit .~ nil
      |> Reward.lens.endsAt .~ nil

    self.vm.inputs.configureWith(project: .template, rewardOrBacking: .left(reward))

    self.pillCollectionViewHidden.assertValues([true])
    self.reloadPills.assertValues([[]])
  }

  // State Icon Image

  func testStateIconImage_BackedReward() {
    self.stateIconImageName.assertValueCount(0)
    self.stateIconImageTintColor.assertValueCount(0)
    self.stateIconImageViewContainerBackgroundColor.assertValueCount(0)
    self.stateIconImageViewContainerHidden.assertValueCount(0)

    let reward = Reward.postcards

    let project = Project.cosmicSurgery
      |> Project.lens.state .~ .live
      |> Project.lens.personalization.isBacking .~ true
      |> Project.lens.personalization.backing .~ (
        .template
          |> Backing.lens.reward .~ reward
          |> Backing.lens.rewardId .~ reward.id
          |> Backing.lens.shippingAmount .~ 10
          |> Backing.lens.amount .~ 700
      )

    self.vm.inputs.configureWith(
      project: project,
      rewardOrBacking: .left(reward)
    )

    self.stateIconImageName.assertValues(["checkmark-reward"])
    self.stateIconImageTintColor.assertValues([.ksr_blue_500])
    self.stateIconImageViewContainerBackgroundColor.assertValues(
      [UIColor.ksr_blue_500.withAlphaComponent(0.06)]
    )
    self.stateIconImageViewContainerHidden.assertValues([false])
  }

  func testStateIconImage_BackedOtherReward() {
    self.stateIconImageName.assertValueCount(0)
    self.stateIconImageTintColor.assertValueCount(0)
    self.stateIconImageViewContainerBackgroundColor.assertValueCount(0)
    self.stateIconImageViewContainerHidden.assertValueCount(0)

    let reward = Reward.postcards

    let project = Project.cosmicSurgery
      |> Project.lens.state .~ .live
      |> Project.lens.personalization.isBacking .~ true
      |> Project.lens.personalization.backing .~ (
        .template
          |> Backing.lens.reward .~ Reward.otherReward
          |> Backing.lens.rewardId .~ Reward.otherReward.id
          |> Backing.lens.shippingAmount .~ 10
          |> Backing.lens.amount .~ 700
      )

    self.vm.inputs.configureWith(
      project: project,
      rewardOrBacking: .left(reward)
    )

    self.stateIconImageName.assertValues([])
    self.stateIconImageTintColor.assertValues([])
    self.stateIconImageViewContainerBackgroundColor.assertValues([])
    self.stateIconImageViewContainerHidden.assertValues([true])
  }

  func testStateIconImage_BackedRewardErrored() {
    self.stateIconImageName.assertValueCount(0)
    self.stateIconImageTintColor.assertValueCount(0)
    self.stateIconImageViewContainerBackgroundColor.assertValueCount(0)
    self.stateIconImageViewContainerHidden.assertValueCount(0)

    let reward = Reward.postcards

    let project = Project.cosmicSurgery
      |> Project.lens.state .~ .live
      |> Project.lens.personalization.isBacking .~ true
      |> Project.lens.personalization.backing .~ (
        .template
          |> Backing.lens.status .~ .errored
          |> Backing.lens.reward .~ reward
          |> Backing.lens.rewardId .~ reward.id
          |> Backing.lens.shippingAmount .~ 10
          |> Backing.lens.amount .~ 700
      )

    self.vm.inputs.configureWith(
      project: project,
      rewardOrBacking: .left(reward)
    )

    self.stateIconImageName.assertValues(["icon--alert"])
    self.stateIconImageTintColor.assertValues([.ksr_apricot_500])
    self.stateIconImageViewContainerBackgroundColor.assertValues(
      [UIColor.ksr_apricot_500.withAlphaComponent(0.06)]
    )
    self.stateIconImageViewContainerHidden.assertValues([false])
  }

  func testStateIconImage_NonBacked() {
    self.stateIconImageName.assertValueCount(0)
    self.stateIconImageTintColor.assertValueCount(0)
    self.stateIconImageViewContainerBackgroundColor.assertValueCount(0)
    self.stateIconImageViewContainerHidden.assertValueCount(0)

    let reward = Reward.postcards

    let project = Project.cosmicSurgery
      |> Project.lens.state .~ .live
      |> Project.lens.personalization.isBacking .~ false

    self.vm.inputs.configureWith(
      project: project,
      rewardOrBacking: .left(reward)
    )

    self.stateIconImageName.assertValues([])
    self.stateIconImageTintColor.assertValues([])
    self.stateIconImageViewContainerBackgroundColor.assertValues([])
    self.stateIconImageViewContainerHidden.assertValues([true])
  }
}
